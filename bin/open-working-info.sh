#!/bin/bash
# open-working-info.sh — Abre ~/Documents/Working Info e aciona o preset Rectangle
# Disparado por skhd (cmd+alt+w). Requer permissão "Acessibilidade" para o skhd
# (já necessária para o resto do skhdrc).
#
# Background: o Finder não faz scaling nativo, portanto redimensiona-se a
# imagem source para o tamanho exacto da janela via `sips` e aplica-se essa
# versão cacheada. Converte-se para JPEG para achatar o canal alfa — caso
# contrário o Finder em dark mode compõe as zonas translúcidas sobre o fundo
# escuro da janela e escurece a imagem toda (ver exports do Excalidraw).
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

  -- 3. Ler tamanho real da icon view via Accessibility — é onde o Finder
  --    desenha a background picture. Usamos `role = "AXScrollArea"` (em vez
  --    de `class is scroll area`, que não estava a fazer match) para
  --    encontrar as scroll areas em qualquer nível da hierarquia. Registamos
  --    posição+tamanho de todas, erros do AX, e os bounds da janela para
  --    comparação.
  set winW to 0
  set winH to 0
  try
    tell application "Finder"
      set b to bounds of win
      do shell script "echo " & quoted form of ("window bounds: " & (item 1 of b) & "," & (item 2 of b) & " -> " & (item 3 of b) & "," & (item 4 of b) & " size=" & ((item 3 of b) - (item 1 of b)) & "x" & ((item 4 of b) - (item 2 of b))) & " >> " & quoted form of logPath
    end tell
  end try
  set axLog to "AX: start" & linefeed
  try
    tell application "System Events"
      tell process "Finder"
        set winCount to count of windows
        set axLog to axLog & "AX: windows=" & winCount & linefeed
        if winCount > 0 then
          set allElems to entire contents of window 1
          set axLog to axLog & "AX: entire contents count=" & (count of allElems) & linefeed
          set elemIdx to 0
          set maxW to 0
          repeat with elem in allElems
            set elemIdx to elemIdx + 1
            try
              set eRole to role of elem
              set eSize to size of elem
              set ePos to position of elem
              set axLog to axLog & "  [" & elemIdx & "] role=" & eRole & " pos=" & (item 1 of ePos) & "," & (item 2 of ePos) & " size=" & (item 1 of eSize) & "x" & (item 2 of eSize) & linefeed
              if eRole is "AXScrollArea" and (item 1 of eSize) > maxW then
                set maxW to item 1 of eSize
                set winW to item 1 of eSize
                set winH to item 2 of eSize
              end if
            on error elemErr
              set axLog to axLog & "  [" & elemIdx & "] elem error: " & elemErr & linefeed
            end try
          end repeat
        end if
      end tell
    end tell
  on error axErr
    set axLog to axLog & "AX error: " & axErr & linefeed
  end try
  do shell script "/bin/cat >> " & quoted form of logPath & " <<'LOGEOF'
" & axLog & "LOGEOF"
  if winW = 0 or winH = 0 then
    try
      tell application "Finder"
        set b to bounds of win
        set winW to (item 3 of b) - (item 1 of b)
        set winH to (item 4 of b) - (item 2 of b) - 28
      end tell
    end try
  end if
  do shell script "date '+%F %T icon view: " & winW & "x" & winH & "' >> " & quoted form of logPath

  -- 4. Redimensionar source para o tamanho exacto da icon view e aplicar.
  if bgSource is not "" and winW > 0 and winH > 0 then
    try
      do shell script "/usr/bin/sips -s format jpeg -s formatOptions 90 -z " & winH & " " & winW & " " & quoted form of bgSource & " --out " & quoted form of bgCache & " >/dev/null 2>>" & quoted form of logPath
      do shell script "/usr/bin/sips -g pixelHeight -g pixelWidth " & quoted form of bgCache & " | /usr/bin/awk '/pixel/ {printf \"  output %s=%s\\n\", $1, $2}' >> " & quoted form of logPath
      tell application "Finder"
        tell icon view options of win
          set background picture to (POSIX file bgCache as alias)
        end tell
      end tell
    on error errMsg
      do shell script "echo " & quoted form of ("bg-stretch error: " & errMsg) & " >> " & quoted form of logPath
    end try
  end if
end run
EOF
