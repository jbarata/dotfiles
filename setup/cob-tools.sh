#!/bin/bash
# setup/cob-tools.sh — Instalar CLIs COB (cob-cli + cob-md-to-pdf + cob-aia linkados)
set -euo pipefail

SRC_DIR="$HOME/.local/src"
CLI_DIR="$SRC_DIR/cob-cli"
CLI_REPO="git@github.com:cob/cob-cli.git"
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

mkdir -p "$SRC_DIR"

# Clone (ou actualizar) + checkout opcional da branch remota mais recente
# (committerdate) cujo nome contenha "branch_pref" como substring + npm
# install + npm link
link_cob_repo() {
    local name="$1"
    local repo="$2"
    local dir="$3"
    local with_build="${4:-}"
    local branch_pref="${5:-}"

    if [[ -d "$dir/.git" ]]; then
        echo "  A actualizar $dir..."
        git -C "$dir" pull --quiet --ff-only
    else
        echo "  A clonar $repo → $dir..."
        git clone --quiet "$repo" "$dir"
    fi

    if [[ -n "$branch_pref" ]]; then
        git -C "$dir" fetch --quiet --prune origin
        local match
        match="$(git -C "$dir" for-each-ref \
            --format='%(refname:lstrip=3)' \
            --sort=-committerdate \
            refs/remotes/origin/ \
            | grep -v '^HEAD$' \
            | { grep -F -- "$branch_pref" || true; } \
            | head -n1)"
        if [[ -n "$match" ]]; then
            echo "  Checkout de $match em $name (mais recente com '$branch_pref' no nome)..."
            git -C "$dir" checkout --quiet "$match"
            git -C "$dir" pull --quiet --ff-only
        else
            echo "  Nenhuma branch com '$branch_pref' no nome em $name; a manter branch atual."
        fi
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

# --- cob-cli (clone + checkout da branch *beta* mais recente + npm link) ---
# Remover instalação global antiga de cob-cli (única vez). Se já estivermos
# a usar `npm link`, $(npm root -g)/cob-cli é symlink — saltamos.
NPM_ROOT_G="$(npm root -g)"
if [[ -d "$NPM_ROOT_G/cob-cli" && ! -L "$NPM_ROOT_G/cob-cli" ]]; then
    echo "  A remover instalação global anterior de cob-cli..."
    npm uninstall -g cob-cli
fi
link_cob_repo "cob-cli" "$CLI_REPO" "$CLI_DIR" "" "beta"

# --- cob-md-to-pdf (clone + npm i + npm link) ---
link_cob_repo "cob-md-to-pdf" "$MD_TO_PDF_REPO" "$MD_TO_PDF_DIR"

# --- cob-aia (clone + npm i + npm link) ---
link_cob_repo "cob-aia" "$AIA_REPO" "$AIA_DIR" build

# --- cob-aia zsh completion (autoloaded via fpath em ~/.zsh/completions) ---
AIA_COMP_SRC="$AIA_DIR/completions/cob-aia.zsh"
AIA_COMP_DST="$HOME/.zsh/completions/_cob-aia"
if [[ -f "$AIA_COMP_SRC" ]]; then
    mkdir -p "$(dirname "$AIA_COMP_DST")"
    if [[ -L "$AIA_COMP_DST" && "$(readlink "$AIA_COMP_DST")" == "$AIA_COMP_SRC" ]]; then
        echo "  cob-aia completion: symlink já correcto"
    else
        [[ -e "$AIA_COMP_DST" || -L "$AIA_COMP_DST" ]] && rm -f "$AIA_COMP_DST"
        ln -s "$AIA_COMP_SRC" "$AIA_COMP_DST"
        echo "  Link: $AIA_COMP_DST → $AIA_COMP_SRC"
        # Invalidar cache do compinit para reconhecer o novo completer
        rm -f "$HOME/.zcompdump"* 2>/dev/null || true
    fi
else
    echo "  AVISO: $AIA_COMP_SRC não existe; a saltar completion do cob-aia."
fi

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
