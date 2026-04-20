#!/bin/bash
# safari-to-note.sh — Salva a página actual do Safari como nota do Notes.app
# numa versão "reader-friendly" (título + corpo + imagens inline) com o link
# original e a tag #site. Disparado pelo skhd (shift+ctrl+alt+cmd+n).
#
# Como funciona (3 passos):
#   1. AppleScript → Safari: lê URL/título e injecta JS para extrair o
#      conteúdo principal (<article>/<main>/[itemprop=articleBody] ou o
#      contentor com melhor score de texto/<p>/<img>); grava em temp files.
#   2. Python: descarrega cada <img src="http…"> e substitui por data: URI
#      base64 (Notes.app não descarrega remotos quando o body é fixado via
#      AppleScript — inline é obrigatório para as imagens aparecerem).
#   3. AppleScript → Notes: lê HTML inlinado e cria nova nota com H1
#      título, link para a página original, tag #site e o artigo.
#
# Pré-requisitos (uma vez):
#   - Safari → Preferences → Advanced → "Show Develop menu in menu bar".
#   - Safari → Develop → "Allow JavaScript from Apple Events".
#   - python3 no PATH (vem com Xcode CLI Tools).
#   - skhd já tem permissão "Acessibilidade".
#
# Logs (debug): /tmp/safari-to-note.log
set -euo pipefail

LOG="/tmp/safari-to-note.log"
HUD="/tmp/skhd-mode"   # skhd-hud.widget faz poll a 100ms e renderiza inline
DEBUG_RAW="/tmp/safari-to-note-article.html"
DEBUG_INLINED="/tmp/safari-to-note-article-inlined.html"
TMPDIR="$(mktemp -d -t safari-to-note 2>/dev/null || mktemp -d /tmp/safari-to-note.XXXXXX)"

# Formato do HUD: `mode|hint1 | hint2 | …`. Limpa no fim (vazio → invisível).
hud() { echo "$1" > "$HUD"; }
cleanup() {
	cp -f "$TMPDIR/article.html" "$DEBUG_RAW" 2>/dev/null || true
	cp -f "$TMPDIR/article-inlined.html" "$DEBUG_INLINED" 2>/dev/null || true
	rm -rf "$TMPDIR"
	echo "" > "$HUD" 2>/dev/null || true
}
trap cleanup EXIT

# Identifica a versão que está a correr (sha curto do repo) para que o
# log diga sempre que commit foi executado — evita diagnosticar versão errada.
VERSION="$(cd "$(dirname "$0")/.." 2>/dev/null && git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"

echo "--- $(date '+%F %T') start ($TMPDIR) v=$VERSION ---" >> "$LOG"
hud "Safari → Notes|A extrair página…"

# ---------------------------------------------------------------------------
# Passo 1 — Extrair título, URL e HTML do Safari para ficheiros temporários.
# ---------------------------------------------------------------------------
osascript - "$TMPDIR" <<'APPLESCRIPT' 2>>"$LOG"
on run argv
	set outDir to item 1 of argv

	set jsCode to "(function(){
  function abs(u){ try{ return new URL(u, document.baseURI).href; }catch(e){ return u || ''; } }
  function scoreEl(el){
    if(!el) return 0;
    var t = (el.innerText||'').trim().length;
    var p = el.querySelectorAll('p').length;
    var i = el.querySelectorAll('img,picture').length;
    return t + p*50 + i*30;
  }
  var clone = document.cloneNode(true);
  var drop = 'script,style,noscript,nav,aside,header,footer,form,button,iframe,.ad,.ads,.advertisement,.sidebar,.share,.social,.comments,.related,.newsletter,.cookie,.cookies';
  clone.querySelectorAll(drop).forEach(function(e){ e.remove(); });
  // Unwrap <picture> para manter apenas o <img> interno (Notes não percebe picture+source).
  clone.querySelectorAll('picture').forEach(function(pic){
    var img = pic.querySelector('img');
    if(img){ pic.parentNode.insertBefore(img, pic); }
    pic.remove();
  });
  var selectors = ['article','main','[role=main]','[itemprop=articleBody]','.article-body','.post-content','.entry-content','.article','.post','.entry','.content'];
  var best = null; var bestScore = 0;
  selectors.forEach(function(sel){
    Array.prototype.forEach.call(clone.querySelectorAll(sel), function(el){
      var s = scoreEl(el);
      if(s > bestScore){ best = el; bestScore = s; }
    });
  });
  if(!best || bestScore < 200) best = clone.body;
  // Substack-style proxy: https://<host>/p/<transform>/<url-encoded-original>
  // devolve 404 fora do contexto Safari. Extrai o URL original.
  function unproxy(u){
    if(!u) return u;
    var m = u.match(/^https?:\\/\\/[^/]+\\/p\\/[^/]+\\/(https?%3[aA]%2[fF]%2[fF][^?]+)/);
    if(m){ try{ return decodeURIComponent(m[1]); }catch(e){} }
    m = u.match(/^https?:\\/\\/[^/]+\\/p\\/[^/]+\\/(https?:\\/\\/[^?]+)/);
    if(m) return m[1];
    return u;
  }
  // Escolhe o melhor src: prefere data-attrs.src (Substack embute o URL
  // real em JSON aqui), srcset(maior), data-*, depois src. Evita
  // placeholders data:image/svg e proxy URLs que devolvem 404.
  best.querySelectorAll('img').forEach(function(img){
    var candidates = [];
    // Substack: <img data-attrs='{\"src\":\"https://...\"}'> tem o URL real.
    var dataAttrs = img.getAttribute('data-attrs');
    if(dataAttrs){
      try {
        var parsed = JSON.parse(dataAttrs);
        if(parsed && parsed.src) candidates.push(parsed.src);
        if(parsed && parsed.srcNoWatermark) candidates.push(parsed.srcNoWatermark);
      } catch(e){}
    }
    var srcset = img.getAttribute('srcset') || img.getAttribute('data-srcset') || '';
    if(srcset){
      var parts = srcset.split(',');
      var last = parts[parts.length - 1].trim().split(/\\s+/)[0];
      if(last) candidates.push(last);
    }
    ['data-src','data-lazy-src','data-original','data-hi-res-src','data-full-src'].forEach(function(a){
      var v = img.getAttribute(a);
      if(v) candidates.push(v);
    });
    var rawSrc = img.getAttribute('src') || '';
    if(rawSrc) candidates.push(rawSrc);
    // Primeiro candidato que seja http(s) real (não placeholder data:).
    var finalSrc = '';
    for(var i=0; i<candidates.length; i++){
      var c = (candidates[i] || '').trim();
      if(!c) continue;
      if(c.indexOf('data:') === 0) continue;      // placeholder SVG/GIF
      if(c.indexOf('javascript:') === 0) continue;
      finalSrc = unproxy(c); break;
    }
    if(finalSrc){
      img.setAttribute('src', abs(finalSrc));
    } else {
      img.remove();   // sem URL real: remove (evita 'File' no Notes)
      return;
    }
    ['srcset','data-srcset','data-src','data-lazy-src','data-original','data-hi-res-src','data-full-src','data-attrs','loading','decoding'].forEach(function(a){
      img.removeAttribute(a);
    });
  });
  best.querySelectorAll('a[href]').forEach(function(a){
    a.setAttribute('href', abs(a.getAttribute('href')));
  });
  best.querySelectorAll('*').forEach(function(el){
    ['style','class','id','onclick','onload','data-test','role','aria-hidden','tabindex'].forEach(function(a){ el.removeAttribute(a); });
  });
  return best.innerHTML;
})();"

	tell application "Safari"
		if (count of windows) is 0 then
			my notify("Safari → Notes", "Nenhuma janela Safari aberta")
			error "no safari window" number 1001
		end if
		set currentTab to current tab of front window
		set currentURL to URL of currentTab
		set currentTitle to (name of currentTab) as text
		try
			set articleHTML to (do JavaScript jsCode in currentTab) as text
		on error errMsg
			my notify("Safari → Notes", "do JavaScript falhou: " & errMsg)
			error errMsg number 1002
		end try
	end tell

	if articleHTML is "" or articleHTML is missing value then
		my notify("Safari → Notes", "Conteúdo vazio — página não extraível")
		error "empty content" number 1003
	end if

	my writeUTF8(outDir & "/title.txt", currentTitle)
	my writeUTF8(outDir & "/url.txt", currentURL)
	my writeUTF8(outDir & "/article.html", articleHTML)
end run

on writeUTF8(posixPath, content)
	set fd to open for access (POSIX file posixPath) with write permission
	try
		set eof of fd to 0
		write content to fd as «class utf8»
	on error errMsg
		close access fd
		error errMsg
	end try
	close access fd
end writeUTF8

on notify(t, m)
	try
		display notification m with title t
	end try
end notify
APPLESCRIPT

if [ ! -s "$TMPDIR/article.html" ]; then
	echo "extraction failed — no article.html" >> "$LOG"
	hud "Safari → Notes|Falha na extracção (ver /tmp/safari-to-note.log)"
	sleep 2
	exit 1
fi

IMG_COUNT=$(grep -oc '<img' "$TMPDIR/article.html" 2>/dev/null || echo 0)
hud "Safari → Notes|A inlinar ${IMG_COUNT} imagens (pode demorar)…"

# ---------------------------------------------------------------------------
# Passo 2 — Descarregar imagens e substituir por data: URIs (Notes inline).
# ---------------------------------------------------------------------------
python3 - "$TMPDIR" <<'PYTHON' 2>>"$LOG"
import sys, re, base64, mimetypes, ssl, subprocess, tempfile, os
import urllib.request, urllib.parse

out_dir = sys.argv[1]
src_path = f"{out_dir}/article.html"
dst_path = f"{out_dir}/article-inlined.html"

with open(src_path, "r", encoding="utf-8") as f:
    html = f.read()

MAX_BYTES = 3 * 1024 * 1024  # 3MB por imagem
TIMEOUT = 10

# Notes.app renderiza inline só estes formatos; os restantes ficam como
# "File" placeholder. Converte-se o resto para PNG via sips (built-in macOS).
INLINE_OK = {"image/png", "image/jpeg", "image/gif"}


def detect_mime(data):
    """Detecta formato por magic bytes — mais fiável que Content-Type."""
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return "image/png"
    if data[:3] == b"\xff\xd8\xff":
        return "image/jpeg"
    if data[:6] in (b"GIF87a", b"GIF89a"):
        return "image/gif"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    if len(data) >= 12 and data[4:8] == b"ftyp" and data[8:12] in (
        b"avif", b"avis", b"heic", b"heix", b"mif1", b"msf1"
    ):
        return "image/heic" if data[8:12] in (b"heic", b"heix") else "image/avif"
    if data[:5] == b"<?xml" or data[:4] == b"<svg":
        return "image/svg+xml"
    return None


def to_png_via_sips(data):
    """Converte bytes (qualquer formato que o sips leia) para PNG."""
    in_fd, in_path = tempfile.mkstemp(prefix="s2n-in-", suffix=".bin")
    out_path = in_path + ".png"
    try:
        with os.fdopen(in_fd, "wb") as f:
            f.write(data)
        r = subprocess.run(
            ["/usr/bin/sips", "-s", "format", "png", in_path, "--out", out_path],
            capture_output=True, timeout=20
        )
        if r.returncode == 0 and os.path.exists(out_path):
            with open(out_path, "rb") as f:
                return f.read()
        sys.stderr.write(f"sips fail rc={r.returncode}: {r.stderr.decode('utf-8', 'replace')[:200]}\n")
    except Exception as e:
        sys.stderr.write(f"sips exception: {e}\n")
    finally:
        for p in (in_path, out_path):
            try: os.unlink(p)
            except OSError: pass
    return None


def unproxy(url):
    """Extrai URL original de proxies tipo Substack
    (https://<host>/p/<transform>/<url-encoded-original>)."""
    m = re.match(r"^https?://[^/]+/p/[^/]+/(https?%3[aA]%2[fF]%2[fF][^?]+)", url)
    if m:
        try: return urllib.parse.unquote(m.group(1))
        except Exception: pass
    m = re.match(r"^https?://[^/]+/p/[^/]+/(https?://[^?]+)", url)
    if m: return m.group(1)
    return None


def _do_fetch(url):
    req = urllib.request.Request(url, headers={
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X) Safari/605",
        "Accept": "image/*,*/*;q=0.8",
    })
    try:
        return urllib.request.urlopen(req, timeout=TIMEOUT)
    except ssl.SSLError:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        return urllib.request.urlopen(req, timeout=TIMEOUT, context=ctx)


def fetch_data_uri(url):
    try:
        try:
            resp = _do_fetch(url)
        except urllib.error.HTTPError as e:
            # Fallback: proxy URL (ex. Substack) que devolve 404 fora do
            # contexto do browser → tenta o URL original embebido.
            unp = unproxy(url)
            if unp and unp != url:
                sys.stderr.write(f"retry unproxy: {url[:80]} → {unp[:80]}\n")
                resp = _do_fetch(unp)
            else:
                raise
        with resp as r:
            data = r.read(MAX_BYTES + 1)
            if len(data) > MAX_BYTES:
                sys.stderr.write(f"skip (too large): {url}\n")
                return None
        detected = detect_mime(data)
        mime = detected or (r.headers.get("Content-Type") or "").split(";")[0].strip().lower()
        if not mime or not mime.startswith("image/"):
            guess = mimetypes.guess_type(url)[0]
            mime = guess if guess and guess.startswith("image/") else "image/jpeg"
        # Converte formatos não-renderizáveis pelo Notes para PNG.
        if mime not in INLINE_OK:
            converted = to_png_via_sips(data)
            if converted:
                data, mime = converted, "image/png"
                sys.stderr.write(f"converted → png: {url}\n")
            else:
                sys.stderr.write(f"convert failed ({mime}): {url}\n")
                return None  # Melhor skip do que "File" placeholder no Notes.
        return f"data:{mime};base64,{base64.b64encode(data).decode('ascii')}"
    except Exception as e:
        sys.stderr.write(f"fetch fail {url}: {e}\n")
        return None

img_re = re.compile(r'''<img\b[^>]*?\bsrc=(["'])(.*?)\1[^>]*>''', re.IGNORECASE | re.DOTALL)

cache = {}
count_ok = 0
count_skip = 0

def replace(match):
    global count_ok, count_skip
    quote = match.group(1)
    src = match.group(2).strip()
    if not src:
        count_skip += 1
        sys.stderr.write("skip (empty src)\n")
        return ""
    if src.startswith("data:"):
        # Inline PNG/JPEG/GIF legítimos ficam; placeholders SVG etc. removidos.
        if src.startswith(("data:image/png;", "data:image/jpeg;", "data:image/jpg;", "data:image/gif;")):
            count_skip += 1
            sys.stderr.write("keep (valid data: inline)\n")
            return match.group(0)
        count_skip += 1
        sys.stderr.write(f"drop (data: placeholder, {src[:40]}...)\n")
        return ""
    if not src.startswith(("http://", "https://")):
        count_skip += 1
        sys.stderr.write(f"drop (non-http src: {src[:60]})\n")
        return ""
    if src in cache:
        data_uri = cache[src]
    else:
        data_uri = fetch_data_uri(src)
        cache[src] = data_uri
    if not data_uri:
        count_skip += 1
        return ""
    count_ok += 1
    return match.group(0).replace(quote + match.group(2) + quote, quote + data_uri + quote, 1)

html_inlined = img_re.sub(replace, html)

with open(dst_path, "w", encoding="utf-8") as f:
    f.write(html_inlined)

sys.stderr.write(f"images inlined: {count_ok}, skipped: {count_skip}\n")
PYTHON

if [ ! -s "$TMPDIR/article-inlined.html" ]; then
	# Fallback: se Python falhou, usa o HTML original (imagens ficam remotas).
	echo "python inlining failed — falling back to remote image refs" >> "$LOG"
	cp "$TMPDIR/article.html" "$TMPDIR/article-inlined.html"
fi

hud "Safari → Notes|A criar nota…"

# ---------------------------------------------------------------------------
# Passo 3 — Criar a nota no Notes.app com corpo HTML + imagens inline.
# ---------------------------------------------------------------------------
osascript - "$TMPDIR" <<'APPLESCRIPT' 2>>"$LOG"
on run argv
	set outDir to item 1 of argv
	set titleText to my readUTF8(outDir & "/title.txt")
	set urlText to my readUTF8(outDir & "/url.txt")
	set htmlText to my readUTF8(outDir & "/article-inlined.html")

	-- Body: só link + tag + artigo. O título da nota vem do `name:` abaixo;
	-- não injectamos <h1> extra para não duplicar com o H1 nativo do artigo.
	set noteBody to "<p><a href=\"" & urlText & "\">" & urlText & "</a></p>" & ¬
		"<p>#site</p>" & ¬
		htmlText

	tell application "Notes"
		activate
		try
			make new note with properties {name:titleText, body:noteBody}
		on error errMsg
			my notify("Safari → Notes", "Falha a criar nota: " & errMsg)
			error errMsg number 1010
		end try
	end tell

	my notify("Safari → Notes", "Nota criada: " & titleText)
end run

on readUTF8(posixPath)
	set fd to open for access (POSIX file posixPath)
	try
		set content to read fd as «class utf8»
	on error errMsg
		close access fd
		error errMsg
	end try
	close access fd
	return content
end readUTF8

on escapeHTML(s)
	set s to my replaceAll(s, "&", "&amp;")
	set s to my replaceAll(s, "<", "&lt;")
	set s to my replaceAll(s, ">", "&gt;")
	return s
end escapeHTML

on replaceAll(src, old, new)
	set AppleScript's text item delimiters to old
	set parts to text items of src
	set AppleScript's text item delimiters to new
	set out to parts as text
	set AppleScript's text item delimiters to ""
	return out
end replaceAll

on notify(t, m)
	try
		display notification m with title t
	end try
end notify
APPLESCRIPT
