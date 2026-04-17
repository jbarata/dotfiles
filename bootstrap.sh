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

BACKUP_FILES=(
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.aliases"
    "$HOME/.exports"
    "$HOME/.gitconfig"
    "$HOME/.ssh/config"
    "$HOME/.config/ghostty/config"
)

for f in "${BACKUP_FILES[@]}"; do
    if [[ -e "$f" && ! -L "$f" ]]; then
        NEED_BACKUP=true
        break
    fi
done

if $NEED_BACKUP; then
    echo "==> A fazer backup de ficheiros existentes..."
    if $DRY_RUN; then
        for f in "${BACKUP_FILES[@]}"; do
            [[ -e "$f" && ! -L "$f" ]] && echo "  [dry-run] backup $f → $BACKUP_DIR/"
        done
    else
        mkdir -p "$BACKUP_DIR"
        for f in "${BACKUP_FILES[@]}"; do
            if [[ -e "$f" && ! -L "$f" ]]; then
                local_name=$(basename "$f")
                cp "$f" "$BACKUP_DIR/$local_name"
                rm "$f"
                echo "  Backup: $f"
            fi
        done
        echo "  Guardado em: $BACKUP_DIR/"
    fi
else
    echo "==> Nenhum ficheiro para backup (já são symlinks ou não existem)"
fi

# --- 5. Criar symlinks (stow + manuais) ---
echo "==> A criar symlinks..."
if $DRY_RUN; then
    echo "  [dry-run] stow git shell ssh ghostty"
    echo "  [dry-run] link VS Code settings, keybindings, snippets"
    echo "  [dry-run] link Claude Code settings, CLAUDE.md"
else
    bash "$DOTFILES/setup/symlinks.sh"
fi

# --- 6. Mudar remote para SSH (1Password agent) ---
echo "==> A configurar git remote via SSH..."
CURRENT_REMOTE=$(git -C "$DOTFILES" remote get-url origin 2>/dev/null || true)
if [[ "$CURRENT_REMOTE" == https://* ]]; then
    SSH_REMOTE=$(echo "$CURRENT_REMOTE" | sed 's|https://github.com/|git@github.com:|')
    run git -C "$DOTFILES" remote set-url origin "$SSH_REMOTE"
    echo "  Remote alterado: $SSH_REMOTE"
else
    echo "  Remote já usa SSH"
fi

# --- 7. Instalar extensões VS Code ---
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

# --- 8. Configurar Übersicht widgets ---
if [[ -f "$DOTFILES/ubersicht/install.sh" ]]; then
    echo "==> A configurar Übersicht widgets..."
    if $DRY_RUN; then
        echo "  [dry-run] git clone/pull Ubersicht-Widgets"
    else
        bash "$DOTFILES/ubersicht/install.sh"
    fi
fi

# --- 9. macOS defaults (opcional) ---
if [[ -f "$DOTFILES/setup/macos-defaults.sh" ]]; then
    echo "==> A aplicar preferências macOS..."
    if $DRY_RUN; then
        echo "  [dry-run] defaults write (Finder, Screenshots, Teclado)"
    else
        bash "$DOTFILES/setup/macos-defaults.sh"
    fi
fi

# --- 10. Criar directoria de cache fzf ---
mkdir -p "$HOME/.cache"

echo ""
echo "==> Bootstrap completo! Reinicia o terminal para aplicar todas as mudanças."
echo "    Máquina: $MACHINE ($ARCH)"
echo "    Homebrew: $BREW_PREFIX"
if [[ -d "$BACKUP_DIR" ]]; then
    echo "    Backups: $BACKUP_DIR/"
fi
