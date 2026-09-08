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

# Verificar `engines` do package.json antes do npm install. Alguns repos COB
# (ex: cob-press) exigem node/npm mais recentes do que os instalados e trazem
# `engine-strict` — o npm aborta com EBADENGINE em vez de só avisar, e o
# `set -e` deste script matava todo o resto do setup (Utils, cmd-line-importer).
# npm aquém do exigido actualiza-se sozinho (fica na versão de node activa do
# nvm); node aquém é avisado e o repo saltado — trocar de node é decisão do
# utilizador, não deste setup.
check_engines() {
    local name="$1"
    local dir="$2"
    local pkg="$dir/package.json"
    [[ -f "$pkg" ]] || return 0

    # Extrair o primeiro número semver do range (">=24" → "24", "^11.16.0" → "11.16.0")
    local req_node req_npm
    req_node="$(node -p "const e=(require('$pkg').engines||{}).node||'';const m=e.match(/\d+(?:\.\d+)*/);m?m[0]:''" 2>/dev/null || true)"
    req_npm="$(node -p "const e=(require('$pkg').engines||{}).npm||'';const m=e.match(/\d+(?:\.\d+)*/);m?m[0]:''" 2>/dev/null || true)"

    if [[ -n "$req_node" ]]; then
        local cur_node
        cur_node="$(node -p 'process.versions.node')"
        if [[ "$(printf '%s\n%s\n' "$req_node" "$cur_node" | sort -V | head -n1)" != "$req_node" ]]; then
            echo "  AVISO: $name exige node >= $req_node (tens $cur_node); a saltar."
            echo "         Actualiza com 'nvm install $req_node && nvm alias default $req_node' e corre este setup outra vez."
            return 1
        fi
    fi

    if [[ -n "$req_npm" ]]; then
        local cur_npm
        cur_npm="$(npm --version)"
        if [[ "$(printf '%s\n%s\n' "$req_npm" "$cur_npm" | sort -V | head -n1)" != "$req_npm" ]]; then
            echo "  npm $cur_npm < $req_npm (exigido por $name); a actualizar npm..."
            npm install -g "npm@$req_npm"
        fi
    fi
}

# Ficheiros que as ferramentas regeneram sozinhas e que sujam a working copy.
# O `npm install` deste script reescreve quase sempre o package-lock.json (npm/
# node diferentes de quem gerou o lock) e no bootstrap seguinte o `git checkout`
# recusa-se a trocar de branch. Descartamo-los antes de tocar no git — o
# `npm install` volta a gerá-los logo a seguir.
REGENERATED_FILES=("package-lock.json")

discard_regenerated() {
    local dir="$1"
    local f st

    # Se o package.json também está alterado, o lock pode ser uma mudança de
    # dependências a sério — não é este setup que a deita fora.
    if [[ -n "$(git -C "$dir" status --porcelain -- package.json)" ]]; then
        return 0
    fi

    for f in "${REGENERATED_FILES[@]}"; do
        st="$(git -C "$dir" status --porcelain -- "$f")"
        [[ -z "$st" ]] && continue
        [[ "$st" == "??"* ]] && continue   # untracked: não é nosso para apagar
        echo "  A descartar $f (regenerado pelo npm install)..."
        git -C "$dir" checkout --quiet HEAD -- "$f"
    done
}

# Alterações locais em ficheiros versionados (untracked não contam — não
# impedem checkout nem pull)
repo_is_dirty() {
    [[ -n "$(git -C "$1" status --porcelain --untracked-files=no)" ]]
}

report_dirty() {
    local name="$1"
    local dir="$2"
    local what="$3"
    echo "  AVISO: $name tem alterações locais por commitar — a saltar $what:"
    git -C "$dir" status --short --untracked-files=no | sed 's/^/    /'
}

# Resolver e fazer checkout da branch preferida. "branch_pref": se existir uma
# branch remota com esse nome exacto é essa; senão a mais recente
# (committerdate) cujo nome o contenha como substring ("beta" → "beta-1.2.3").
checkout_branch() {
    local name="$1"
    local dir="$2"
    local branch_pref="$3"

    git -C "$dir" fetch --quiet --prune origin
    local match=""
    if git -C "$dir" show-ref --verify --quiet "refs/remotes/origin/$branch_pref"; then
        match="$branch_pref"
        echo "  Checkout de $match em $name..."
    else
        match="$(git -C "$dir" for-each-ref \
            --format='%(refname:lstrip=3)' \
            --sort=-committerdate \
            refs/remotes/origin/ \
            | grep -v '^HEAD$' \
            | { grep -F -- "$branch_pref" || true; } \
            | head -n1)"
        if [[ -z "$match" ]]; then
            echo "  Nenhuma branch com '$branch_pref' no nome em $name; a manter branch atual."
            git -C "$dir" pull --quiet --ff-only \
                || echo "  AVISO: pull falhou em $name; a manter estado local."
            return 0
        fi
        echo "  Checkout de $match em $name (mais recente com '$branch_pref' no nome)..."
    fi
    git -C "$dir" checkout --quiet "$match"
    git -C "$dir" pull --quiet --ff-only
}

# Clone (ou actualizar) + checkout opcional de branch + npm install + npm link.
# "branch_pref" resolve-se assim: se existir uma branch remota com esse nome
# exacto é essa; senão usa-se a mais recente (committerdate) cujo nome o
# contenha como substring (ex: "beta" → "beta-1.2.3").
link_cob_repo() {
    local name="$1"
    local repo="$2"
    local dir="$3"
    local with_build="${4:-}"
    local branch_pref="${5:-}"

    if [[ -d "$dir/.git" ]]; then
        discard_regenerated "$dir"
        if repo_is_dirty "$dir"; then
            # Trabalho por commitar: não é este setup que o descarta nem que
            # rebenta com o bootstrap todo por causa dele.
            report_dirty "$name" "$dir" "checkout/pull"
        elif [[ -n "$branch_pref" ]]; then
            # Com branch_pref o update faz-se dentro do checkout_branch: a
            # branch actual do clone pode já não existir no remoto (ex: clones
            # antigos numa branch beta apagada) e o pull rebentava com tudo.
            checkout_branch "$name" "$dir" "$branch_pref"
        else
            echo "  A actualizar $dir..."
            git -C "$dir" pull --quiet --ff-only
        fi
    else
        echo "  A clonar $repo → $dir..."
        git clone --quiet "$repo" "$dir"
        if [[ -n "$branch_pref" ]]; then
            checkout_branch "$name" "$dir" "$branch_pref"
        fi
    fi

    check_engines "$name" "$dir" || return 0

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
        discard_regenerated "$dir"
        if repo_is_dirty "$dir"; then
            report_dirty "$(basename "$dir")" "$dir" "pull"
        else
            echo "  A actualizar $dir..."
            git -C "$dir" pull --quiet --ff-only
        fi
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
    # --- cob-cli (clone + checkout da branch *master* + npm link) ---
    # Remover instalação global antiga de cob-cli (única vez). Se já estivermos
    # a usar `npm link`, $(npm root -g)/cob-cli é symlink — saltamos.
    NPM_ROOT_G="$(npm root -g)"
    if [[ -d "$NPM_ROOT_G/cob-cli" && ! -L "$NPM_ROOT_G/cob-cli" ]]; then
        echo "  A remover instalação global anterior de cob-cli..."
        npm uninstall -g cob-cli
    fi
    link_cob_repo "cob-cli" "$CLI_REPO" "$CLI_DIR" "" "master"

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
