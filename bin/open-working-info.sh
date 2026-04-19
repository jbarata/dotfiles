#!/bin/bash
# open-working-info.sh — Abre ~/Documents/Working Info e aciona o preset Rectangle
# Disparado por skhd (cmd+alt+w). Requer permissão "Acessibilidade" para o skhd
# (já necessária para o resto do skhdrc).
set -euo pipefail

TARGET="$HOME/Documents/Working Info"
mkdir -p "$TARGET"

# Abrir (ou focar) a janela do Finder em icon view.
# Se já existir janela aberta em Working Info, reutiliza; caso contrário cria.
osascript - "$TARGET" <<'EOF'
on run argv
  set targetPath to item 1 of argv
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
    set index of win to 1
  end tell
end run
EOF

# Pequeno delay para a janela ganhar foco antes de enviar o keystroke.
# Se o redimensionamento falhar, aumentar para 0.4.
sleep 0.25

# Envia Ctrl+Option+Return → atalho global do Rectangle para o preset desejado.
# key code 36 = Return.
osascript -e 'tell application "System Events" to key code 36 using {control down, option down}'
