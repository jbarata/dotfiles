#!/bin/bash
# open-working-info.sh — Abre ~/Documents/Working Info e aciona o preset Rectangle
# Disparado por skhd (cmd+alt+w). Requer permissão "Acessibilidade" para o skhd
# (já necessária para o resto do skhdrc).
set -euo pipefail

TARGET="$HOME/Documents/Working Info"
# Background opcional: se existir, é aplicado como icon view background.
BG="$HOME/.dotfiles/assets/working-info-bg.png"
# Tamanho do ícone em pixels (16-128). Default Finder = 64.
ICON_SIZE=96
# Log para debug (erros do AppleScript relativos ao background).
LOG="/tmp/working-info.log"
mkdir -p "$TARGET"

# Só passa o path do bg se o ficheiro realmente existir, para não disparar
# "file not found" em POSIX file ... as alias.
if [[ -f "$BG" ]]; then
  BG_ARG="$BG"
else
  BG_ARG=""
  echo "$(date '+%F %T') bg missing: $BG" >> "$LOG"
fi

# Abrir (ou focar) a janela do Finder em icon view, sem toolbar/sidebar
# (traditional window), com tamanho de ícones fixo e background se disponível.
osascript - "$TARGET" "$BG_ARG" "$ICON_SIZE" "$LOG" <<'EOF' 2>>"$LOG" || true
on run argv
  set targetPath to item 1 of argv
  set bgPath to item 2 of argv
  set iconSize to (item 3 of argv) as integer
  set logPath to item 4 of argv
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
    set index of win to 1
    -- Pequena pausa para a janela ficar pronta antes de aplicar icon view opts.
    delay 0.15
    tell icon view options of win
      set icon size to iconSize
      set arrangement to not arranged
      if bgPath is not "" then
        try
          set background picture to (POSIX file bgPath as alias)
        on error errMsg
          do shell script "echo " & quoted form of ("bg error: " & errMsg) & " >> " & quoted form of logPath
        end try
      end if
    end tell
  end tell
end run
EOF

# Pequeno delay para a janela ganhar foco antes de enviar o keystroke.
# Se o redimensionamento falhar, aumentar para 0.4.
sleep 0.25

# Envia Ctrl+Option+Return → atalho global do Rectangle para o preset desejado.
# key code 36 = Return.
osascript -e 'tell application "System Events" to key code 36 using {control down, option down}'
