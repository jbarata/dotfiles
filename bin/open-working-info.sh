#!/bin/bash
# open-working-info.sh — Abre ~/Documents/Working Info e aciona o preset Rectangle
# Disparado por skhd (cmd+alt+w). Requer permissão "Acessibilidade" para o skhd
# (já necessária para o resto do skhdrc).
#
# Background: o Finder desenha a background picture ao "natural point size"
# da imagem (pixels × 72 ÷ DPI), não ao pixel size. Se a source tem DPI ≠ 72
# (ex.: exports do Excalidraw usam ~63 DPI), mesmo que o sips redimensione
# para o pixel count certo, a imagem aparece maior/menor do que a icon view
# por causa da DPI. Por isso forçamos dpiWidth=dpiHeight=72 no output para
# garantir que 1 pixel = 1 point. Também convertemos para JPEG para achatar
# o canal alfa — caso contrário o Finder em dark mode compõe as zonas
# translúcidas sobre o fundo escuro da janela.
set -euo pipefail

TARGET="$HOME/Documents/Working Info"
# Imagem source (aspect ratio livre — será esticada para caber na janela).
BG_SOURCE="$HOME/Documents/Working Info/background.png"
# Imagem cacheada no tamanho da janela actual. Path único por invocação —
# o Finder cacheia a background picture por path, por isso reutilizar o
# mesmo filename faz com que nunca veja o conteúdo novo.
BG_CACHE="/tmp/working-info-bg-$(date +%s%N).jpg"
# Tamanho do ícone em pixels (16-128). Default Finder = 64.
ICON_SIZE=32
# Log para debug.
LOG="/tmp/working-info.log"
mkdir -p "$TARGET"

# Limpar caches antigos (>10 min) para não encher /tmp.
find /tmp -maxdepth 1 -name 'working-info-bg-*.jpg' -mmin +10 -delete 2>/dev/null || true

if [[ ! -f "$BG_SOURCE" ]]; then
  echo "$(date '+%F %T') bg source missing: $BG_SOURCE" >> "$LOG"
  BG_SOURCE=""
fi

osascript - "$TARGET" "$BG_SOURCE" "$BG_CACHE" "$ICON_SIZE" "$LOG" <<'EOF' 2>>"$LOG" || true
on run argv
  set targetPath to item 1 of argv
  set bgSource to item 2 of argv
  set bgCache to item 3 of argv
  set iconSize to (item 4 of argv) as integer
  set logPath to item 5 of argv

  -- 1. Abrir/focar janela em icon view, sem toolbar.
  tell application "Finder"
    activate
    set targetFolder to POSIX file targetPath as alias
    set win to missing value
    repeat with w in windows
      try
        if (target of w as alias) is equal to targetFolder then
          set win to w
          exit repeat
        end if
      end try
    end repeat
    if win is missing value then
      set win to make new Finder window to targetFolder
    else
      set target of win to targetFolder
    end if
    set current view of win to icon view
    set toolbar visible of win to false
    try
      set statusbar visible of win to false
    end try
    try
      set pathbar visible of win to false
    end try
    try
      set sidebar width of win to 0
    end try
    set index of win to 1
    delay 0.15
    tell icon view options of win
      set icon size to iconSize
      set arrangement to not arranged
    end tell
  end tell

  -- 2. Disparar preset do Rectangle (Ctrl+Option+Return).
  tell application "System Events" to key code 36 using {control down, option down}
  delay 0.3

  -- 3. Ler tamanho da icon view via Accessibility e aplicar padding empírico.
  --    A AXScrollArea reporta o viewport (ex. 1668x993) mas o Finder desenha
  --    o background picture numa AXList aninhada com padding interno (~4px
  --    laterais, 10 em cima, 20 em baixo — 8 largura, 30 altura no total).
  --    Esses valores foram observados no log diagnóstico. Fallback: bounds da
  --    janela menos title bar (32pt) menos o mesmo padding.
  set winW to 0
  set winH to 0
  try
    tell application "System Events"
      tell process "Finder"
        set targetWin to first window whose name is "Working Info"
        set maxW to 0
        repeat with elem in (entire contents of targetWin)
          try
            if role of elem is "AXScrollArea" then
              set eSize to size of elem
              if (item 1 of eSize) > maxW then
                set maxW to item 1 of eSize
                set winW to item 1 of eSize
                set winH to item 2 of eSize
              end if
            end if
          end try
        end repeat
      end tell
    end tell
  end try
  if winW = 0 or winH = 0 then
    try
      tell application "Finder"
        set b to bounds of win
        set winW to (item 3 of b) - (item 1 of b)
        set winH to (item 4 of b) - (item 2 of b) - 32
      end tell
    end try
  end if
  -- Subtrair padding interno da icon view (drawable area < scroll area).
  if winW > 8 then set winW to winW - 8
  if winH > 30 then set winH to winH - 30
  do shell script "date '+%F %T icon view: " & winW & "x" & winH & "' >> " & quoted form of logPath

  -- 4. Redimensionar source para o tamanho exacto da icon view e aplicar.
  --    Nota: usamos a sintaxe directa `set background picture of icon view
  --    options of win to ...` em vez de nested tell, que estava a perder
  --    scope e a tentar fazer `set win to alias` em vez de setar a
  --    property.
  if bgSource is not "" and winW > 0 and winH > 0 then
    try
      do shell script "/usr/bin/sips -s format jpeg -s formatOptions 90 -s dpiWidth 72 -s dpiHeight 72 -z " & winH & " " & winW & " " & quoted form of bgSource & " --out " & quoted form of bgCache & " 2>>" & quoted form of logPath
      tell application "Finder"
        set current view of win to icon view
        set background picture of icon view options of win to (POSIX file bgCache as alias)
      end tell
    on error errMsg
      do shell script "echo " & quoted form of ("bg-stretch error: " & errMsg) & " >> " & quoted form of logPath
    end try
  end if
end run
EOF
