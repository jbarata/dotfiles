#!/bin/bash
# setup/vscode-extensions.sh — Instalar extensões VS Code a partir da lista
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
EXTENSIONS_FILE="$DOTFILES/vscode/extensions.txt"

if [[ ! -f "$EXTENSIONS_FILE" ]]; then
    echo "  AVISO: $EXTENSIONS_FILE não encontrado. Corre 'vscode-export' primeiro."
    exit 0
fi

echo "  A instalar extensões VS Code..."
while IFS= read -r ext; do
    # Ignorar linhas vazias e comentários
    [[ -z "$ext" || "$ext" == //* ]] && continue
    echo "    → $ext"
    code --install-extension "$ext" --force 2>/dev/null || echo "    AVISO: falhou $ext"
done < "$EXTENSIONS_FILE"
