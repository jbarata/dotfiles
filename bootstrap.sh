#!/bin/bash
# bootstrap.sh — Setup one-command para novo Mac
# Uso: git clone https://github.com/mimes70/dotfiles.git ~/.dotfiles && ~/.dotfiles/bootstrap.sh
# Dry-run: ~/.dotfiles/bootstrap.sh --dry-run
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "==> MODO DRY-RUN: nenhuma alteração será feita"
    echo ""
fi

run() {
    if $DRY_RUN; then
        echo "  [dry-run] $*"
    else
        "$@"
    fi
}

# --- Deteção de arquitetura ---
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    BREW_PREFIX="/opt/homebrew"
    MACHINE="macbook"
else
    BREW_PREFIX="/usr/local"
    MACHINE="imac"
fi

echo "==> Máquina detetada: $ARCH ($MACHINE) — Homebrew em $BREW_PREFIX"

# --- 1. Instalar Homebrew se não existir ---
if ! command -v brew &>/dev/null; then
    echo "==> A instalar Homebrew..."
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    run eval "$($BREW_PREFIX/bin/brew shellenv)"
else
    echo "==> Homebrew já instalado"
fi

# --- 2. Instalar dependências via Brewfile ---
echo "==> A instalar pacotes Homebrew..."
run brew bundle --file="$DOTFILES/Brewfile" || true
if [[ -f "$DOTFILES/Brewfile.$MACHINE" ]]; then
    echo "==> A instalar pacotes específicos ($MACHINE)..."
    run brew bundle --file="$DOTFILES/Brewfile.$MACHINE" || true
fi

# --- 3. Instalar NVM ---
if [[ ! -d "$HOME/.nvm" ]]; then
    echo "==> A instalar NVM..."
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh)"
else
    echo "==> NVM já instalado"
fi

# --- 4. Backup de ficheiros existentes ---
BACKUP_DIR="$HOME/dotfiles-backup/pre-bootstrap-$(date +%Y%m%d-%H%M%S)"
NEED_BACKUP=false

# Pares: ficheiro local | ficheiro no repo
PAIRS=(
    "$HOME/.zshrc|$DOTFILES/shell/.zshrc"
    "$HOME/.zprofile|$DOTFILES/shell/.zprofile"
    "$HOME/.aliases|$DOTFILES/shell/.aliases"
    "$HOME/.exports|$DOTFILES/shell/.exports"
    "$HOME/.gitconfig|$DOTFILES/git/.gitconfig"
    "$HOME/.ssh/config|$DOTFILES/ssh/.ssh/config"
    "$HOME/.config/ghostty/config|$DOTFILES/ghostty/.config/ghostty/config"
    "$HOME/.vimrc|$DOTFILES/vim/.vimrc"
)

# Detectar ficheiros reais (a fazer backup) e symlinks stale (a remover)
STALE_LINKS=()
for pair in "${PAIRS[@]}"; do
    local_f="${pair%%|*}"
    repo_f="${pair##*|}"
    if [[ -L "$local_f" ]]; then
        # Symlink — verificar se aponta para o repo
        current_target=$(readlink "$local_f")
        if [[ "$current_target" != "$repo_f" ]]; then
            STALE_LINKS+=("$local_f|$current_target")
        fi
    elif [[ -e "$local_f" ]]; then
        NEED_BACKUP=true
    fi
done

if $NEED_BACKUP || [[ ${#STALE_LINKS[@]} -gt 0 ]]; then
    # --- 4a. Mostrar diferenças e symlinks stale ---
    echo "==> Diferenças entre ficheiros actuais e repo:"
    echo ""
    for pair in "${PAIRS[@]}"; do
        local_f="${pair%%|*}"
        repo_f="${pair##*|}"
        if [[ -e "$local_f" && ! -L "$local_f" ]]; then
            if [[ -f "$repo_f" ]]; then
                DIFF_OUTPUT=$(diff "$local_f" "$repo_f" 2>/dev/null || true)
                if [[ -n "$DIFF_OUTPUT" ]]; then
                    echo "--- $local_f vs $repo_f ---"
                    echo "$DIFF_OUTPUT"
                    echo ""
                else
                    echo "  $local_f — sem diferenças"
                fi
            else
                echo "  $local_f — novo (não existe no repo)"
            fi
        fi
    done

    if [[ ${#STALE_LINKS[@]} -gt 0 ]]; then
        echo ""
        echo "==> Symlinks a substituir (apontam para fora do repo):"
        for stale in "${STALE_LINKS[@]}"; do
            link="${stale%%|*}"
            target="${stale##*|}"
            echo "  $link → $target"
        done
    fi

    if ! $DRY_RUN; then
        echo ""
        read -rp "==> Continuar com backup e substituição? [s/N] " REPLY
        if [[ ! "$REPLY" =~ ^[sS]$ ]]; then
            echo "==> Abortado. Nenhuma alteração feita."
            exit 0
        fi
    fi

    # --- 4b. Backup de ficheiros reais e remoção de symlinks stale ---
    echo "==> A fazer backup e limpar..."
    if $DRY_RUN; then
        for pair in "${PAIRS[@]}"; do
            local_f="${pair%%|*}"
            [[ -e "$local_f" && ! -L "$local_f" ]] && echo "  [dry-run] backup $local_f → $BACKUP_DIR/"
        done
        for stale in "${STALE_LINKS[@]}"; do
            link="${stale%%|*}"
            echo "  [dry-run] remove symlink $link"
        done
    else
        mkdir -p "$BACKUP_DIR"
        for pair in "${PAIRS[@]}"; do
            local_f="${pair%%|*}"
            if [[ -e "$local_f" && ! -L "$local_f" ]]; then
                local_name=$(basename "$local_f")
                cp "$local_f" "$BACKUP_DIR/$local_name"
                rm "$local_f"
                echo "  Backup: $local_f"
            fi
        done
        for stale in "${STALE_LINKS[@]}"; do
            link="${stale%%|*}"
            target="${stale##*|}"
            echo "$link → $target" >> "$BACKUP_DIR/stale-symlinks.log"
            rm "$link"
            echo "  Removed stale symlink: $link"
        done
        echo "  Guardado em: $BACKUP_DIR/"
    fi
else
    echo "==> Nenhum ficheiro para backup (já são symlinks ou não existem)"
fi

# --- 5. Criar symlinks (stow + manuais) ---
echo "==> A criar symlinks..."
if $DRY_RUN; then
    echo "  [dry-run] stow git shell vim ssh ghostty"
    echo "  [dry-run] link VS Code settings, keybindings, snippets"
    echo "  [dry-run] link Claude Code settings, CLAUDE.md"
else
    bash "$DOTFILES/setup/symlinks.sh"
fi

# --- 6. Instalar plugins vim ---
if [[ -f "$DOTFILES/setup/vim-plugins.sh" ]]; then
    echo "==> A instalar plugins vim..."
    if $DRY_RUN; then
        echo "  [dry-run] git clone $(grep -c '^https' "$DOTFILES/setup/vim-plugins.txt") plugins → ~/.vim/pack/dotfiles/start/"
    else
        bash "$DOTFILES/setup/vim-plugins.sh"
    fi
fi

# --- 7. Mudar remote para SSH (1Password agent) ---
echo "==> A configurar git remote via SSH..."
CURRENT_REMOTE=$(git -C "$DOTFILES" remote get-url origin 2>/dev/null || true)
if [[ "$CURRENT_REMOTE" == https://* ]]; then
    SSH_REMOTE=$(echo "$CURRENT_REMOTE" | sed 's|https://github.com/|git@github.com:|')
    run git -C "$DOTFILES" remote set-url origin "$SSH_REMOTE"
    echo "  Remote alterado: $SSH_REMOTE"
else
    echo "  Remote já usa SSH"
fi

# --- 8. Instalar extensões VS Code ---
if command -v code &>/dev/null && [[ -f "$DOTFILES/vscode/extensions.txt" ]]; then
    echo "==> A instalar extensões VS Code..."
    if $DRY_RUN; then
        echo "  [dry-run] code --install-extension ($(wc -l < "$DOTFILES/vscode/extensions.txt") extensões)"
    else
        bash "$DOTFILES/setup/vscode-extensions.sh"
    fi
else
    echo "==> VS Code: não encontrado ou sem extensions.txt, a saltar"
fi

# --- 9. Configurar Übersicht widgets ---
if [[ -f "$DOTFILES/setup/ubersicht.sh" ]]; then
    echo "==> A configurar Übersicht widgets..."
    if $DRY_RUN; then
        echo "  [dry-run] symlink ubersicht/widgets → ~/Library/Application Support/Übersicht/widgets"
    else
        bash "$DOTFILES/setup/ubersicht.sh"
    fi
fi

# --- 9b. Iniciar serviço skhd ---
if [[ -f "$DOTFILES/setup/skhd.sh" ]]; then
    echo "==> A iniciar serviço skhd..."
    if $DRY_RUN; then
        echo "  [dry-run] brew services start/restart skhd"
    else
        bash "$DOTFILES/setup/skhd.sh"
    fi
fi

# --- 10. macOS defaults (opcional) ---
if [[ -f "$DOTFILES/setup/macos-defaults.sh" ]]; then
    echo "==> A aplicar preferências macOS..."
    if $DRY_RUN; then
        echo "  [dry-run] defaults write (Finder, Screenshots, Teclado)"
    else
        bash "$DOTFILES/setup/macos-defaults.sh"
    fi
fi

# --- 11. Criar directoria de cache fzf ---
mkdir -p "$HOME/.cache"

echo ""
echo "==> Bootstrap completo! Reinicia o terminal para aplicar todas as mudanças."
echo "    Máquina: $MACHINE ($ARCH)"
echo "    Homebrew: $BREW_PREFIX"
if [[ -d "$BACKUP_DIR" ]]; then
    echo "    Backups: $BACKUP_DIR/"
fi
