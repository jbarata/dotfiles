#!/bin/bash
# bootstrap.sh — Setup one-command para novo Mac
# Uso: git clone https://github.com/mimes70/dotfiles.git ~/.dotfiles && ~/.dotfiles/bootstrap.sh
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

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
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$($BREW_PREFIX/bin/brew shellenv)"
fi

# --- 2. Instalar dependências via Brewfile ---
echo "==> A instalar pacotes Homebrew..."
brew bundle --file="$DOTFILES/Brewfile" || true
if [[ -f "$DOTFILES/Brewfile.$MACHINE" ]]; then
    echo "==> A instalar pacotes específicos ($MACHINE)..."
    brew bundle --file="$DOTFILES/Brewfile.$MACHINE" || true
fi

# --- 3. Criar symlinks ---
echo "==> A criar symlinks..."
source "$DOTFILES/setup/symlinks.sh"

# --- 4. Configurar iTerm2 para usar dotfiles ---
echo "==> A configurar iTerm2..."
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$DOTFILES/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

# --- 5. Instalar extensões VS Code ---
if command -v code &>/dev/null && [[ -f "$DOTFILES/vscode/extensions.txt" ]]; then
    echo "==> A instalar extensões VS Code..."
    source "$DOTFILES/setup/vscode-extensions.sh"
fi

# --- 6. Configurar Übersicht widgets ---
echo "==> A configurar Übersicht widgets..."
source "$DOTFILES/ubersicht/install.sh"

# --- 7. Configurar SSH com 1Password agent ---
echo "==> A configurar SSH..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh
if [[ ! -f ~/.ssh/config ]] || ! grep -q "IdentityAgent" ~/.ssh/config; then
    cat >> ~/.ssh/config << 'SSHEOF'

# 1Password SSH Agent
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
SSHEOF
    chmod 600 ~/.ssh/config
fi

# --- 8. macOS defaults (opcional) ---
if [[ -f "$DOTFILES/setup/macos-defaults.sh" ]]; then
    echo "==> A aplicar preferências macOS..."
    source "$DOTFILES/setup/macos-defaults.sh"
fi

echo ""
echo "==> Bootstrap completo! Reinicia o terminal para aplicar todas as mudanças."
echo "    Máquina: $MACHINE ($ARCH)"
echo "    Homebrew: $BREW_PREFIX"
