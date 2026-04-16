#!/bin/bash
# ubersicht/install.sh — Instalar/atualizar Übersicht widgets
set -euo pipefail

WIDGETS_DIR="$HOME/Library/Application Support/Übersicht/widgets"
REPO_URL="https://github.com/mimes70/Ubersicht-Widgets.git"

mkdir -p "$WIDGETS_DIR"

if [[ -d "$WIDGETS_DIR/Ubersicht-Widgets/.git" ]]; then
    echo "  Übersicht widgets: a atualizar..."
    cd "$WIDGETS_DIR/Ubersicht-Widgets" && git pull
else
    echo "  Übersicht widgets: a clonar..."
    git clone "$REPO_URL" "$WIDGETS_DIR/Ubersicht-Widgets"
fi
