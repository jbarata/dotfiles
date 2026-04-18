#!/bin/bash
# setup/ubersicht.sh — Symlink da pasta de widgets Übersicht
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
WIDGETS_SRC="$DOTFILES/ubersicht/widgets"
WIDGETS_DST="$HOME/Library/Application Support/Übersicht/widgets"
BACKUP_DIR="$HOME/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

mkdir -p "$(dirname "$WIDGETS_DST")"

if [[ -L "$WIDGETS_DST" && "$(readlink "$WIDGETS_DST")" == "$WIDGETS_SRC" ]]; then
    echo "  Übersicht widgets: symlink já correcto"
    exit 0
fi

# Backup se for directoria real (widgets instalados por outra via)
if [[ -d "$WIDGETS_DST" && ! -L "$WIDGETS_DST" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$WIDGETS_DST" "$BACKUP_DIR/ubersicht-widgets"
    echo "  Backup: $WIDGETS_DST → $BACKUP_DIR/ubersicht-widgets"
fi

# Remover symlink antigo a apontar para lado errado
if [[ -L "$WIDGETS_DST" ]]; then
    rm "$WIDGETS_DST"
fi

ln -s "$WIDGETS_SRC" "$WIDGETS_DST"
echo "  Link: $WIDGETS_DST → $WIDGETS_SRC"
