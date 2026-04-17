#!/bin/bash
# ubersicht/install.sh — Instalar/atualizar Übersicht widgets
set -euo pipefail

WIDGETS_DIR="$HOME/Library/Application Support/Übersicht/widgets"
REPO_URL="git@github.com:mimes70/Ubersicht-Widgets.git"

mkdir -p "$WIDGETS_DIR"

if [[ -d "$WIDGETS_DIR/Ubersicht-Widgets/.git" ]]; then
    echo "  Übersicht widgets: a atualizar..."
    # Migrar remote para SSH se ainda for HTTPS
    cd "$WIDGETS_DIR/Ubersicht-Widgets"
    CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || true)
    if [[ "$CURRENT_REMOTE" == https://* ]]; then
        git remote set-url origin "$REPO_URL"
        echo "  Remote alterado para SSH"
    fi
    git pull
else
    echo "  Übersicht widgets: a clonar..."
    git clone "$REPO_URL" "$WIDGETS_DIR/Ubersicht-Widgets"
fi
