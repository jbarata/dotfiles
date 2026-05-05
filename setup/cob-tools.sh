#!/bin/bash
# setup/cob-tools.sh — Instalar CLIs COB (cob-cli@beta + cob-md-to-pdf + cob-aia linkados)
set -euo pipefail

SRC_DIR="$HOME/.local/src"
MD_TO_PDF_DIR="$SRC_DIR/cob-md-to-pdf"
MD_TO_PDF_REPO="git@github.com:cob/cob-md-to-pdf.git"
AIA_DIR="$SRC_DIR/cob-aia"
AIA_REPO="git@github.com:cob/cob-aia.git"

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

mkdir -p "$SRC_DIR"

# Clone (ou actualizar) + npm install + npm link de um repo COB
link_cob_repo() {
    local name="$1"
    local repo="$2"
    local dir="$3"
    local with_build="${4:-}"

    if [[ -d "$dir/.git" ]]; then
        echo "  A actualizar $dir..."
        git -C "$dir" pull --quiet --ff-only
    else
        echo "  A clonar $repo → $dir..."
        git clone --quiet "$repo" "$dir"
    fi

    echo "  npm install em $name..."
    (cd "$dir" && npm install)

    if [[ "$with_build" == "build" ]]; then
        echo "  npm run build em $name..."
        (cd "$dir" && npm run build)
    fi

    echo "  npm link em $name..."
    (cd "$dir" && npm link)
}

# --- cob-md-to-pdf (clone + npm i + npm link) ---
link_cob_repo "cob-md-to-pdf" "$MD_TO_PDF_REPO" "$MD_TO_PDF_DIR"

# --- cob-aia (clone + npm i + npm link) ---
link_cob_repo "cob-aia" "$AIA_REPO" "$AIA_DIR" build

# Markdown Preview Enhanced (MPE) lê ~/.local/state/crossnote/style.less e compila-o como Less. Em vez de
# fazer symlink do style.less para um .css (que pode confundir o compilador),
# escrevemos um style.less real que faz @import (inline) do editor-preview.css
# mantido em cob-md-to-pdf — assim o preview do VSCode bate certo com o PDF
# gerado pela CLI.
CROSSNOTE_STYLE="$HOME/.local/state/crossnote/style.less"
EDITOR_PREVIEW_CSS="$MD_TO_PDF_DIR/conf/editor-preview.css"

if [[ ! -f "$EDITOR_PREVIEW_CSS" ]]; then
    echo "  AVISO: $EDITOR_PREVIEW_CSS não existe; a saltar link do style.less."
else
    mkdir -p "$(dirname "$CROSSNOTE_STYLE")"
    if [[ -L "$CROSSNOTE_STYLE" && "$(readlink "$CROSSNOTE_STYLE")" == "$EDITOR_PREVIEW_CSS" ]]; then
        echo "  MPE style.less: symlink já correcto"
    else
        if [[ -e "$CROSSNOTE_STYLE" && ! -L "$CROSSNOTE_STYLE" ]]; then
            backup="$CROSSNOTE_STYLE.bak.$(date +%Y%m%d-%H%M%S)"
            mv "$CROSSNOTE_STYLE" "$backup"
            echo "  Backup: $CROSSNOTE_STYLE → $backup"
        elif [[ -L "$CROSSNOTE_STYLE" ]]; then
            rm "$CROSSNOTE_STYLE"
        fi
        ln -s "$EDITOR_PREVIEW_CSS" "$CROSSNOTE_STYLE"
        echo "  Link: $CROSSNOTE_STYLE → $EDITOR_PREVIEW_CSS"
    fi
fi
