#!/bin/bash
# open-working-info.sh — Abre ~/Documents/Working Info e aciona o preset Rectangle
# Disparado por skhd (cmd+alt+w). Requer permissão "Acessibilidade" para o skhd
# (já necessária para o resto do skhdrc).
set -euo pipefail

TARGET="$HOME/Documents/Working Info"
mkdir -p "$TARGET"

open "$TARGET"

# Pequeno delay para o Finder abrir/focar a janela antes de enviar o keystroke.
# Se o redimensionamento falhar, aumentar para 0.4.
sleep 0.25

# Envia Ctrl+Option+Return → atalho global do Rectangle para o preset desejado.
# key code 36 = Return.
osascript -e 'tell application "System Events" to key code 36 using {control down, option down}'
