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
TMPDIR="$(mktemp -d -t safari-to-note 2>/dev/null || mktemp -d /tmp/safari-to-note.XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "--- $(date '+%F %T') start ($TMPDIR) ---" >> "$LOG"

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
  best.querySelectorAll('img').forEach(function(img){
    var src = img.getAttribute('src') || img.getAttribute('data-src') || img.getAttribute('data-lazy-src') || img.getAttribute('data-original') || '';
    // srcset: escolhe o último candidato (geralmente o maior).
    if((!src || src.indexOf('data:image/svg') === 0) && img.getAttribute('srcset')){
      var parts = img.getAttribute('srcset').split(',');
      var last = parts[parts.length - 1].trim().split(/\\s+/)[0];
      if(last) src = last;
    }
    if(src) img.setAttribute('src', abs(src));
    img.removeAttribute('srcset');
    img.removeAttribute('data-src');
    img.removeAttribute('data-lazy-src');
    img.removeAttribute('data-original');
    img.removeAttribute('loading');
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
	exit 1
fi

# ---------------------------------------------------------------------------
# Passo 2 — Descarregar imagens e substituir por data: URIs (Notes inline).
# ---------------------------------------------------------------------------
python3 - "$TMPDIR" <<'PYTHON' 2>>"$LOG"
import sys, re, base64, mimetypes, ssl, urllib.request, urllib.parse

out_dir = sys.argv[1]
src_path = f"{out_dir}/article.html"
dst_path = f"{out_dir}/article-inlined.html"

with open(src_path, "r", encoding="utf-8") as f:
    html = f.read()

MAX_BYTES = 3 * 1024 * 1024  # 3MB por imagem
TIMEOUT = 10

def fetch_data_uri(url):
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X) Safari/605",
            "Accept": "image/*,*/*;q=0.8",
        })
        try:
            resp = urllib.request.urlopen(req, timeout=TIMEOUT)
        except ssl.SSLError:
            # Fallback sem verificação para CDNs com chain imperfeita.
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            resp = urllib.request.urlopen(req, timeout=TIMEOUT, context=ctx)
        with resp as r:
            data = r.read(MAX_BYTES + 1)
            if len(data) > MAX_BYTES:
                return None
            mime = (r.headers.get("Content-Type") or "").split(";")[0].strip().lower()
            if not mime.startswith("image/"):
                guess = mimetypes.guess_type(url)[0]
                if guess and guess.startswith("image/"):
                    mime = guess
                else:
                    mime = "image/jpeg"
            return f"data:{mime};base64,{base64.b64encode(data).decode('ascii')}"
    except Exception as e:
        sys.stderr.write(f"fetch fail {url}: {e}\n")
        return None

img_re = re.compile(r'''<img\b[^>]*?\bsrc=(["'])(.*?)\1[^>]*>''', re.IGNORECASE | re.DOTALL)

# Cache por URL (mesma imagem pode aparecer várias vezes).
cache = {}
count_ok = 0
count_skip = 0

def replace(match):
    global count_ok, count_skip
    quote = match.group(1)
    src = match.group(2).strip()
    if not src or src.startswith("data:"):
        count_skip += 1
        return match.group(0)
    if not src.startswith(("http://", "https://")):
        count_skip += 1
        return match.group(0)
    if src in cache:
        data_uri = cache[src]
    else:
        data_uri = fetch_data_uri(src)
        cache[src] = data_uri
    if not data_uri:
        count_skip += 1
        return match.group(0)
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

# ---------------------------------------------------------------------------
# Passo 3 — Criar a nota no Notes.app com corpo HTML + imagens inline.
# ---------------------------------------------------------------------------
osascript - "$TMPDIR" <<'APPLESCRIPT' 2>>"$LOG"
on run argv
	set outDir to item 1 of argv
	set titleText to my readUTF8(outDir & "/title.txt")
	set urlText to my readUTF8(outDir & "/url.txt")
	set htmlText to my readUTF8(outDir & "/article-inlined.html")

	set noteBody to "<h1>" & my escapeHTML(titleText) & "</h1>" & ¬
		"<p><a href=\"" & urlText & "\">" & urlText & "</a></p>" & ¬
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
