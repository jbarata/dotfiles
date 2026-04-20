#!/bin/bash
# setup/cob-tools.sh — Instalar CLIs COB (cob-cli@beta + cob-md-to-pdf linkado)
set -euo pipefail

SRC_DIR="$HOME/.local/src"
MD_TO_PDF_DIR="$SRC_DIR/cob-md-to-pdf"
MD_TO_PDF_REPO="git@github.com:cob/cob-md-to-pdf.git"

# Garantir npm no PATH (via nvm default, como em .zshrc)
if ! command -v npm >/dev/null 2>&1; then
    _nvm_dir="${NVM_DIR:-$HOME/.nvm}"
    if [[ -s "$_nvm_dir/alias/default" ]]; then
        _nvm_default=$(<"$_nvm_dir/alias/default")
        while [[ -s "$_nvm_dir/alias/$_nvm_default" ]]; do
            _nvm_default=$(<"$_nvm_dir/alias/$_nvm_default")
        done
        _nvm_bin="$_nvm_dir/versions/node/$_nvm_default/bin"
        [[ -d "$_nvm_bin" ]] && export PATH="$_nvm_bin:$PATH"
    fi
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "  AVISO: npm não encontrado. Instala uma versão node via nvm e define alias default."
    exit 0
fi

echo "  npm: $(command -v npm)"

# --- cob-cli@beta (global) ---
echo "  A instalar cob-cli@beta globalmente..."
npm install -g cob-cli@beta

# --- cob-md-to-pdf (clone + npm i + npm link) ---
mkdir -p "$SRC_DIR"

if [[ -d "$MD_TO_PDF_DIR/.git" ]]; then
    echo "  A actualizar $MD_TO_PDF_DIR..."
    git -C "$MD_TO_PDF_DIR" pull --quiet --ff-only
else
    echo "  A clonar $MD_TO_PDF_REPO → $MD_TO_PDF_DIR..."
    git clone --quiet "$MD_TO_PDF_REPO" "$MD_TO_PDF_DIR"
fi

echo "  npm install em cob-md-to-pdf..."
(cd "$MD_TO_PDF_DIR" && npm install)

echo "  npm link em cob-md-to-pdf..."
(cd "$MD_TO_PDF_DIR" && npm link)
