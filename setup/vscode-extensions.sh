#!/bin/bash
# setup/vscode-extensions.sh — Instalar extensões VS Code a partir da lista
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
EXTENSIONS_FILE="$DOTFILES/vscode/extensions.txt"

if [[ ! -f "$EXTENSIONS_FILE" ]]; then
    echo "  AVISO: $EXTENSIONS_FILE não encontrado. Corre 'vscode-export' primeiro."
    exit 0
fi

if ! command -v code >/dev/null 2>&1; then
    echo "  AVISO: comando 'code' não encontrado; a saltar extensões."
    echo "         Instala-o no VS Code: Command Palette → 'Shell Command: Install code command in PATH'."
    exit 0
fi

# Obter lista de extensões já instaladas (uma única chamada a `code`)
INSTALLED=$(code --list-extensions | tr '[:upper:]' '[:lower:]' | sort -u)

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
FAILED=()
BUILTIN=()
for ext in "${MISSING[@]}"; do
    echo "    → $ext"
    # Capturamos stdout+stderr em vez de os deitar fora: é no stderr que o
    # `code` diz *porquê* falhou (versão incompatível, dependência em falta,
    # rede). Sem isso sobrava "falhou <ext>", sem por onde pegar.
    if out="$(code --install-extension "$ext" --force 2>&1)"; then
        printf '%s\n' "$out" | sed 's/^/      /'
    elif printf '%s' "$out" | grep -q 'is a built-in extension'; then
        # A extensão passou a ser distribuída com o próprio VS Code (foi o caso
        # do github.copilot-chat) e a versão do marketplace é mais antiga — o
        # VS Code recusa o downgrade. Não é falha: é uma linha obsoleta na
        # lista, que o próximo `vscode-export` limpa.
        echo "      Já vem embutida no VS Code — nada a instalar."
        BUILTIN+=("$ext")
    else
        printf '%s\n' "$out" | sed 's/^/      /'
        FAILED+=("$ext")
    fi
done

if [[ ${#BUILTIN[@]} -gt 0 ]]; then
    echo "  NOTA: ${#BUILTIN[@]} extensão(ões) já vêm com o VS Code: ${BUILTIN[*]}"
    echo "        Tira-as de vscode/extensions.txt (ou corre 'vscode-export')."
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo "  AVISO: falhou a instalação de ${#FAILED[@]} extensão(ões): ${FAILED[*]}"
    echo "         Para ver o erro completo: code --install-extension <ext> --force"
fi
