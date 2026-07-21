#!/bin/bash
# safari-to-note.sh — Cria uma nota no Notes.app a partir da página Safari
# activa, em versão "reader-friendly". Disparado por skhd (⇧⌃⌥⌘N).
#
# Imagens: o Notes.app não renderiza `<img>` inline quando o body é fixado
# via AppleScript (trata remotos e data: URIs como attachments "File").
# Diagnosticado empiricamente. Em vez de partir o layout com placeholders
# "File", este script substitui cada `<img>` por `[imagem]` clicável
# apontando para o URL real — o utilizador abre e arrasta para a nota
# manualmente se quiser a imagem.
#
# Substack: o src dos <img> do Substack aponta para um proxy
# (.../p/<transform>/<url-encoded-url>) que só serve com session do browser;
# o URL original (S3 público) é extraído via `unproxy()` — o link do
# placeholder abre directamente no ficheiro real.
#
# Pré-requisitos (uma vez):
#   - Safari → Preferences → Advanced → "Show Develop menu".
#   - Safari → Develop → "Allow JavaScript from Apple Events".
#
# Feedback visual: skhd-hud.widget mostra o estado (polling /tmp/skhd-mode).
# Logs: /tmp/safari-to-note.log
set -euo pipefail

LOG="/tmp/safari-to-note.log"
HUD="/tmp/skhd-mode"

hud() { echo "$1" > "$HUD" 2>/dev/null || true; }
trap 'hud ""' EXIT

VERSION="$(cd "$(dirname "$0")/.." 2>/dev/null && git rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "--- $(date '+%F %T') start v=$VERSION ---" >> "$LOG"
hud "Safari → Notes|A extrair página…"

osascript <<'APPLESCRIPT' 2>>"$LOG"
set jsCode to "(function(){
  function abs(u){ try{ return new URL(u, document.baseURI).href; }catch(e){ return u || ''; } }
  function unproxy(u){
    if(!u) return u;
    var m = u.match(/^https?:\\/\\/[^/]+\\/p\\/[^/]+\\/(https?%3[aA]%2[fF]%2[fF][^?]+)/);
    if(m){ try{ return decodeURIComponent(m[1]); }catch(e){} }
    m = u.match(/^https?:\\/\\/[^/]+\\/p\\/[^/]+\\/(https?:\\/\\/[^?]+)/);
    if(m) return m[1];
    return u;
  }
  function scoreEl(el){
    if(!el) return 0;
    var t = (el.innerText||'').trim().length;
    var p = el.querySelectorAll('p').length;
    return t + p*50;
  }
  var clone = document.cloneNode(true);
  var drop = 'script,style,noscript,nav,aside,header,footer,form,button,iframe,.ad,.ads,.advertisement,.sidebar,.share,.social,.comments,.related,.newsletter,.cookie,.cookies';
  clone.querySelectorAll(drop).forEach(function(e){ e.remove(); });
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
  // Substitui <img> por <p>[imagem]</p> com link para a URL real. Preserva
  // a posição no fluxo do artigo; utilizador embede manualmente se quiser.
  best.querySelectorAll('img').forEach(function(img){
    var candidates = [];
    var dataAttrs = img.getAttribute('data-attrs');
    if(dataAttrs){
      try{ var p = JSON.parse(dataAttrs); if(p && p.src) candidates.push(p.src); }catch(e){}
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
    var finalSrc = '';
    for(var i=0; i<candidates.length; i++){
      var c = (candidates[i]||'').trim();
      if(!c || c.indexOf('data:') === 0 || c.indexOf('javascript:') === 0) continue;
      finalSrc = unproxy(c); break;
    }
    var placeholder = document.createElement('p');
    if(finalSrc){
      var a = document.createElement('a');
      a.href = abs(finalSrc);
      a.textContent = '[imagem]';
      placeholder.appendChild(a);
    } else {
      placeholder.textContent = '[imagem]';
    }
    if(img.parentNode) img.parentNode.replaceChild(placeholder, img);
  });
  best.querySelectorAll('a[href]').forEach(function(a){
    a.setAttribute('href', abs(a.getAttribute('href')));
  });
  best.querySelectorAll('*').forEach(function(el){
    ['style','class','id','onclick','onload','data-test','role','aria-hidden','tabindex','data-attrs','loading','decoding'].forEach(function(a){ el.removeAttribute(a); });
  });
  return best.innerHTML;
})();"

tell application "Safari"
	if (count of windows) is 0 then
		my notify("Safari → Notes", "Nenhuma janela Safari aberta")
		error "no window" number 1001
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

set noteBody to "<p><a href=\"" & currentURL & "\">" & currentURL & "</a></p>" & ¬
	"<p>#site</p>" & articleHTML

tell application "Notes"
	activate
	try
		set newNote to make new note with properties {name:currentTitle, body:noteBody}
		show newNote
	on error errMsg
		my notify("Safari → Notes", "Falha a criar nota: " & errMsg)
		error errMsg number 1010
	end try
end tell

my notify("Safari → Notes", "Nota criada: " & currentTitle)

on notify(t, m)
	try
		display notification m with title t
	end try
end notify
APPLESCRIPT
