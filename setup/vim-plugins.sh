#!/bin/bash
# setup/vim-plugins.sh — Clonar plugins vim para ~/.vim/pack/dotfiles/start/
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
PLUGINS_FILE="$DOTFILES/setup/vim-plugins.txt"
PACK_DIR="$HOME/.vim/pack/dotfiles/start"

if [[ ! -f "$PLUGINS_FILE" ]]; then
    echo "  AVISO: $PLUGINS_FILE não encontrado"
    exit 0
fi

mkdir -p "$PACK_DIR"

UPDATED=0
CLONED=0
UP_TO_DATE=0

while IFS= read -r line; do
    # Ignorar comentários e linhas vazias
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    plugin_name=$(basename "$line" .git)
    plugin_dir="$PACK_DIR/$plugin_name"

    if [[ -d "$plugin_dir/.git" ]]; then
        OLD_HEAD=$(git -C "$plugin_dir" rev-parse HEAD 2>/dev/null || echo "")
        git -C "$plugin_dir" pull --quiet
        NEW_HEAD=$(git -C "$plugin_dir" rev-parse HEAD 2>/dev/null || echo "")
        if [[ "$OLD_HEAD" != "$NEW_HEAD" ]]; then
            echo "  Update: $plugin_name"
            UPDATED=$((UPDATED + 1))
        else
            UP_TO_DATE=$((UP_TO_DATE + 1))
        fi
    else
        echo "  Clone:  $plugin_name"
        git clone --quiet --depth 1 "$line" "$plugin_dir"
        CLONED=$((CLONED + 1))
    fi
done < "$PLUGINS_FILE"

if [[ $UPDATED -eq 0 && $CLONED -eq 0 ]]; then
    echo "  $UP_TO_DATE plugins já actualizados — nada a fazer"
else
    [[ $UP_TO_DATE -gt 0 ]] && echo "  ($UP_TO_DATE plugins já actualizados)"
    # Só regerar helptags se algum plugin mudou
    echo "  A gerar helptags..."
    vim -u NONE -c "helptags ALL" -c "qa!" 2>/dev/null || true
fi
