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

# --- 4. Criar symlinks (stow + manuais) ---
echo "==> A criar symlinks..."
if $DRY_RUN; then
    echo "  [dry-run] stow git shell ssh"
    echo "  [dry-run] link VS Code settings, keybindings, snippets"
    echo "  [dry-run] link Claude Code settings, CLAUDE.md"
else
    source "$DOTFILES/setup/symlinks.sh"
fi

# --- 5. Configurar iTerm2 para usar dotfiles ---
if [[ -d "$DOTFILES/iterm2" ]]; then
    echo "==> A configurar iTerm2..."
    run defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$DOTFILES/iterm2"
    run defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
else
    echo "==> iTerm2: directoria $DOTFILES/iterm2 não existe, a saltar"
fi

# --- 6. Instalar extensões VS Code ---
if command -v code &>/dev/null && [[ -f "$DOTFILES/vscode/extensions.txt" ]]; then
    echo "==> A instalar extensões VS Code..."
    if $DRY_RUN; then
        echo "  [dry-run] code --install-extension ($(wc -l < "$DOTFILES/vscode/extensions.txt") extensões)"
    else
        source "$DOTFILES/setup/vscode-extensions.sh"
    fi
else
    echo "==> VS Code: não encontrado ou sem extensions.txt, a saltar"
fi

# --- 7. Configurar Übersicht widgets ---
if [[ -f "$DOTFILES/ubersicht/install.sh" ]]; then
    echo "==> A configurar Übersicht widgets..."
    if $DRY_RUN; then
        echo "  [dry-run] git clone/pull Ubersicht-Widgets"
    else
        source "$DOTFILES/ubersicht/install.sh"
    fi
fi

# --- 8. macOS defaults (opcional) ---
if [[ -f "$DOTFILES/setup/macos-defaults.sh" ]]; then
    echo "==> A aplicar preferências macOS..."
    if $DRY_RUN; then
        echo "  [dry-run] defaults write (Finder, Screenshots, Teclado)"
    else
        source "$DOTFILES/setup/macos-defaults.sh"
    fi
fi

echo ""
echo "==> Bootstrap completo! Reinicia o terminal para aplicar todas as mudanças."
echo "    Máquina: $MACHINE ($ARCH)"
echo "    Homebrew: $BREW_PREFIX"
