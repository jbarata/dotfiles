#!/bin/bash
# ubersicht/install.sh — Symlink dos widgets Übersicht para a localização oficial
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
WIDGETS_SRC="$DOTFILES/ubersicht/widgets"
WIDGETS_DST="$HOME/Library/Application Support/Übersicht/widgets/Ubersicht-Widgets"
BACKUP_DIR="$HOME/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

mkdir -p "$(dirname "$WIDGETS_DST")"

if [[ -L "$WIDGETS_DST" && "$(readlink "$WIDGETS_DST")" == "$WIDGETS_SRC" ]]; then
    echo "  Übersicht widgets: symlink já correcto"
    exit 0
fi

# Backup se for directoria real (clone antigo do Ubersicht-Widgets)
if [[ -d "$WIDGETS_DST" && ! -L "$WIDGETS_DST" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$WIDGETS_DST" "$BACKUP_DIR/Ubersicht-Widgets"
    echo "  Backup: $WIDGETS_DST → $BACKUP_DIR/Ubersicht-Widgets"
fi

# Remove symlink antigo a apontar para outro lado
if [[ -L "$WIDGETS_DST" ]]; then
    rm "$WIDGETS_DST"
fi

ln -s "$WIDGETS_SRC" "$WIDGETS_DST"
echo "  Link: $WIDGETS_DST → $WIDGETS_SRC"
