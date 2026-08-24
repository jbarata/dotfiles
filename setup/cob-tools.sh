#!/bin/bash
# setup/cob-tools.sh — Instalar CLIs COB (cob-cli + cob-pdf + cob-aia + cob-press
# linkados, Utils/cob + cob-health, cmd-line-importer)
set -euo pipefail

SRC_DIR="$HOME/.local/src"
BIN_DIR="$HOME/.local/bin"
CLI_DIR="$SRC_DIR/cob-cli"
CLI_REPO="git@github.com:cob/cob-cli.git"
PDF_DIR="$SRC_DIR/cob-pdf"
PDF_REPO="git@github.com:cob/cob-pdf.git"
AIA_DIR="$SRC_DIR/cob-aia"
AIA_REPO="git@github.com:cob/cob-aia.git"
PRESS_DIR="$SRC_DIR/cob-press"
PRESS_REPO="git@github.com:cob/cob-press.git"
UTILS_DIR="$SRC_DIR/Utils"
UTILS_REPO="git@github.com:cob/Utils.git"
IMPORTER_DIR="$SRC_DIR/cmd-line-importer"
IMPORTER_REPO="git@github.com:cob/cmd-line-importer.git"

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

HAVE_NPM=true
if ! command -v npm >/dev/null 2>&1; then
    HAVE_NPM=false
    echo "  AVISO: npm não encontrado. Saltam-se cob-cli/cob-pdf/cob-aia/cob-press (instala node via nvm + alias default)."
else
    echo "  npm: $(command -v npm)"
fi

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

# Clonar (ou actualizar) um repo sem npm install/link (para Utils, cmd-line-importer)
clone_or_pull() {
    local repo="$1"
    local dir="$2"

    if [[ -d "$dir/.git" ]]; then
        echo "  A actualizar $dir..."
        git -C "$dir" pull --quiet --ff-only
    else
        echo "  A clonar $repo → $dir..."
        git clone --quiet "$repo" "$dir"
    fi
}

# Criar/refrescar um symlink, idempotente
ensure_symlink() {
    local target="$1"
    local link="$2"

    if [[ ! -e "$target" ]]; then
        echo "  AVISO: $target não existe; a saltar symlink $link."
        return 0
    fi
    mkdir -p "$(dirname "$link")"
    if [[ -L "$link" && "$(readlink "$link")" == "$target" ]]; then
        echo "  Symlink já correcto: $link"
    else
        [[ -e "$link" || -L "$link" ]] && rm -f "$link"
        ln -s "$target" "$link"
        echo "  Link: $link → $target"
    fi
}

if $HAVE_NPM; then
    # --- cob-cli (clone + checkout da branch *beta* mais recente + npm link) ---
    # Remover instalação global antiga de cob-cli (única vez). Se já estivermos
    # a usar `npm link`, $(npm root -g)/cob-cli é symlink — saltamos.
    NPM_ROOT_G="$(npm root -g)"
    if [[ -d "$NPM_ROOT_G/cob-cli" && ! -L "$NPM_ROOT_G/cob-cli" ]]; then
        echo "  A remover instalação global anterior de cob-cli..."
        npm uninstall -g cob-cli
    fi
    link_cob_repo "cob-cli" "$CLI_REPO" "$CLI_DIR" "" "beta"

    # --- cob-pdf (clone + npm i + npm link) ---
    link_cob_repo "cob-pdf" "$PDF_REPO" "$PDF_DIR"

    # --- cob-aia (clone + npm i + npm link) ---
    link_cob_repo "cob-aia" "$AIA_REPO" "$AIA_DIR" build

    # --- cob-press (clone + npm i + npm run build + npm link) ---
    link_cob_repo "cob-press" "$PRESS_REPO" "$PRESS_DIR" build

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
fi

# --- Utils (cob suite via sub + cob-health em Go) -------------------------
clone_or_pull "$UTILS_REPO" "$UTILS_DIR"

# `cob` (sub-based) — `bin/cob` fica em ~/.local/src/Utils/cob/bin via PATH no .zshrc.
# Garantir que é executável (em alguns clones o bit pode não estar definido).
COB_BIN="$UTILS_DIR/cob/bin/cob"
COB_INIT_CACHE="$HOME/.zsh/cob-init.zsh"
if [[ -f "$COB_BIN" ]]; then
    chmod +x "$COB_BIN" 2>/dev/null || true

    # Cachear a saída de `cob init -` para o .zshrc fazer source sem fork por shell.
    # Re-gerado sempre que este setup corre (i.e. após git pull do Utils).
    mkdir -p "$(dirname "$COB_INIT_CACHE")"
    if "$COB_BIN" init - > "$COB_INIT_CACHE.tmp" 2>/dev/null; then
        mv "$COB_INIT_CACHE.tmp" "$COB_INIT_CACHE"
        echo "  Cache: $COB_INIT_CACHE (cob init -)"
    else
        rm -f "$COB_INIT_CACHE.tmp"
        echo "  AVISO: 'cob init -' falhou; cache $COB_INIT_CACHE não actualizado."
    fi
else
    echo "  AVISO: $COB_BIN não existe; verifica o repo Utils."
fi

# cob-health — compilar em Go e symlink em ~/.local/bin/cob-health
COB_HEALTH_DIR="$UTILS_DIR/cob-health"
if [[ -d "$COB_HEALTH_DIR" ]]; then
    if command -v go >/dev/null 2>&1; then
        # cob-health é pré-módulos (Go ≥1.16 exige go.mod). Inicializamos um
        # módulo local se faltar — fica untracked, e somamos os artefactos a
        # .git/info/exclude para não poluírem o `git status` do Utils.
        if [[ ! -f "$COB_HEALTH_DIR/go.mod" ]]; then
            echo "  go mod init em cob-health (módulo em falta)..."
            (cd "$COB_HEALTH_DIR" && go mod init cob-health >/dev/null)
        fi
        UTILS_EXCLUDE="$UTILS_DIR/.git/info/exclude"
        if [[ -f "$UTILS_EXCLUDE" ]]; then
            for pattern in "/cob-health/go.mod" "/cob-health/go.sum" "/cob-health/cob-health"; do
                grep -qxF "$pattern" "$UTILS_EXCLUDE" || echo "$pattern" >> "$UTILS_EXCLUDE"
            done
        fi
        echo "  go build em cob-health..."
        (cd "$COB_HEALTH_DIR" && go build -o cob-health)
        ensure_symlink "$COB_HEALTH_DIR/cob-health" "$BIN_DIR/cob-health"
    else
        echo "  AVISO: go não encontrado; salta build de cob-health (instala via 'brew install go')."
    fi
else
    echo "  AVISO: $COB_HEALTH_DIR não existe; salta cob-health."
fi

# --- cmd-line-importer (searcher / processor / executor) ------------------
clone_or_pull "$IMPORTER_REPO" "$IMPORTER_DIR"

for tool in searcher processor executor; do
    src="$IMPORTER_DIR/${tool}.js"
    if [[ -f "$src" ]]; then
        chmod +x "$src" 2>/dev/null || true
    fi
    ensure_symlink "$src" "$BIN_DIR/$tool"
done

if $HAVE_NPM; then
    # Markdown Preview Enhanced (MPE) lê ~/.local/state/crossnote/style.less e compila-o como Less. Em vez de
    # fazer symlink do style.less para um .css (que pode confundir o compilador),
    # escrevemos um style.less real que faz @import (inline) do editor-preview.css
    # mantido em cob-pdf — assim o preview do VSCode bate certo com o PDF
    # gerado pela CLI.
    CROSSNOTE_STYLE="$HOME/.local/state/crossnote/style.less"
    EDITOR_PREVIEW_CSS="$PDF_DIR/conf/editor-preview.css"

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
fi
