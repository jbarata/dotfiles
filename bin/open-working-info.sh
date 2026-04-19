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
mkdir -p "$TARGET"

# Abrir (ou focar) a janela do Finder em icon view, sem toolbar/sidebar
# (traditional window), com tamanho de ícones fixo e background se disponível.
osascript - "$TARGET" "$BG" "$ICON_SIZE" <<'EOF'
on run argv
  set targetPath to item 1 of argv
  set bgPath to item 2 of argv
  set iconSize to (item 3 of argv) as integer
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
    set icon size of icon view options of win to iconSize
    try
      set bgAlias to POSIX file bgPath as alias
      set background picture of icon view options of win to bgAlias
    end try
  end tell
end run
EOF

# Pequeno delay para a janela ganhar foco antes de enviar o keystroke.
# Se o redimensionamento falhar, aumentar para 0.4.
sleep 0.25

# Envia Ctrl+Option+Return → atalho global do Rectangle para o preset desejado.
# key code 36 = Return.
osascript -e 'tell application "System Events" to key code 36 using {control down, option down}'
