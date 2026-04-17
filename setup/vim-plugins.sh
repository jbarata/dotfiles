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

while IFS= read -r line; do
    # Ignorar comentários e linhas vazias
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    plugin_name=$(basename "$line" .git)
    plugin_dir="$PACK_DIR/$plugin_name"

    if [[ -d "$plugin_dir/.git" ]]; then
        echo "  Update: $plugin_name"
        git -C "$plugin_dir" pull --quiet
    else
        echo "  Clone:  $plugin_name"
        git clone --quiet --depth 1 "$line" "$plugin_dir"
    fi
done < "$PLUGINS_FILE"

# Gerar helptags para todos os plugins
echo "  A gerar helptags..."
vim -u NONE -c "helptags ALL" -c "qa!" 2>/dev/null || true
