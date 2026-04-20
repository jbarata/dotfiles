#!/bin/bash
# safari-to-note.sh — Salva a página actual do Safari como nota do Notes.app
# numa versão "reader-friendly" (título + corpo + imagens) com o link original
# e a tag #site. Disparado pelo skhd (shift+ctrl+alt+cmd+n).
#
# Como funciona:
#   1. Lê URL e título do tab activo do Safari (AppleScript).
#   2. Injecta JavaScript no tab para extrair o conteúdo principal e imagens
#      (heurística leve: procura <article>/<main>/contentor com melhor score
#      de texto/parágrafos/imagens; remove nav/aside/header/footer/ads).
#   3. Normaliza URLs de imagens e links para absolutos.
#   4. Cria uma nova nota no Notes com: H1 título, link para a página,
#      "#site" (tag automática do Notes) e o corpo HTML extraído.
#
# Pré-requisitos (uma vez):
#   - Safari → Preferences → Advanced → "Show Develop menu in menu bar".
#   - Safari → Develop → "Allow JavaScript from Apple Events".
#   - skhd já tem permissão "Acessibilidade" (requerido pelo resto do skhdrc).
#
# Logs (debug): /tmp/safari-to-note.log
set -euo pipefail

LOG="/tmp/safari-to-note.log"

osascript <<'APPLESCRIPT' 2>>"$LOG"
-- Extracção reader-like via Safari do JavaScript + criação de nota no Notes.
-- O JS usa aspas simples em todas as strings para não colidir com a string
-- AppleScript (delimitada por aspas duplas).

set jsCode to "(function(){
  function abs(u){ try{ return new URL(u, document.baseURI).href; }catch(e){ return u || ''; } }
  function scoreEl(el){
    if(!el) return 0;
    var t = (el.innerText||'').trim().length;
    var p = el.querySelectorAll('p').length;
    var i = el.querySelectorAll('img').length;
    return t + p*50 + i*30;
  }
  var clone = document.cloneNode(true);
  var drop = 'script,style,noscript,nav,aside,header,footer,form,button,iframe,.ad,.ads,.advertisement,.sidebar,.share,.social,.comments,.related,.newsletter,.cookie,.cookies';
  clone.querySelectorAll(drop).forEach(function(e){ e.remove(); });
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
    if(src) img.setAttribute('src', abs(src));
    img.removeAttribute('srcset');
    img.removeAttribute('data-src');
    img.removeAttribute('data-lazy-src');
    img.removeAttribute('loading');
  });
  best.querySelectorAll('a[href]').forEach(function(a){
    a.setAttribute('href', abs(a.getAttribute('href')));
  });
  // Remove atributos pesados para aliviar o AppleScript e o Notes.
  best.querySelectorAll('*').forEach(function(el){
    ['style','class','id','onclick','onload','data-test','role','aria-hidden','tabindex'].forEach(function(a){ el.removeAttribute(a); });
  });
  return best.innerHTML;
})();"

tell application "Safari"
	if (count of windows) is 0 then
		my notify("Safari → Notes", "Nenhuma janela Safari aberta")
		return
	end if
	set currentTab to current tab of front window
	set currentURL to URL of currentTab
	set currentTitle to (name of currentTab) as text
	try
		set articleHTML to (do JavaScript jsCode in currentTab) as text
	on error errMsg
		my notify("Safari → Notes", "Falha a extrair conteúdo: " & errMsg)
		return
	end try
end tell

if articleHTML is missing value or articleHTML is "" then
	my notify("Safari → Notes", "Conteúdo vazio — página não extraível")
	return
end if

-- Corpo HTML da nota: título, link, tag #site, e o artigo.
-- A tag #site é detectada pelo Notes.app como hashtag quando gravada.
set noteTitle to currentTitle
set noteBody to "<h1>" & my escapeHTML(currentTitle) & "</h1>" & ¬
	"<p><a href=\"" & currentURL & "\">" & currentURL & "</a></p>" & ¬
	"<p>#site</p>" & ¬
	articleHTML

tell application "Notes"
	activate
	try
		make new note with properties {name:noteTitle, body:noteBody}
	on error errMsg
		my notify("Safari → Notes", "Falha a criar nota: " & errMsg)
		return
	end try
end tell

my notify("Safari → Notes", "Nota criada: " & noteTitle)

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
