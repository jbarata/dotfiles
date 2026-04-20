#!/bin/bash
# setup/vscode-extensions.sh — Instalar extensões VS Code a partir da lista
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
EXTENSIONS_FILE="$DOTFILES/vscode/extensions.txt"

if [[ ! -f "$EXTENSIONS_FILE" ]]; then
    echo "  AVISO: $EXTENSIONS_FILE não encontrado. Corre 'vscode-export' primeiro."
    exit 0
fi

# Obter lista de extensões já instaladas (uma única chamada a `code`)
INSTALLED=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]' | sort -u)

# Separar em falta vs já instaladas
MISSING=()
TOTAL=0
while IFS= read -r ext; do
    [[ -z "$ext" || "$ext" == //* ]] && continue
    TOTAL=$((TOTAL + 1))
    ext_lower=$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')
    if ! grep -qxF "$ext_lower" <<< "$INSTALLED"; then
        MISSING+=("$ext")
    fi
done < "$EXTENSIONS_FILE"

if [[ ${#MISSING[@]} -eq 0 ]]; then
    echo "  $TOTAL extensões já instaladas — nada a fazer"
    exit 0
fi

echo "  A instalar ${#MISSING[@]} extensão(ões) em falta (de $TOTAL)..."
for ext in "${MISSING[@]}"; do
    echo "    → $ext"
    code --install-extension "$ext" --force 2>/dev/null || echo "    AVISO: falhou $ext"
done
