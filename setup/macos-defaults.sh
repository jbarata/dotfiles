#!/bin/bash
# setup/macos-defaults.sh — Preferências macOS via defaults
# NOTA: Personalizar conforme preferência. Estas são sugestões comuns.
set -euo pipefail

echo "  A aplicar preferências macOS..."

# Finder: mostrar extensões de ficheiros
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Finder: mostrar path bar
defaults write com.apple.finder ShowPathbar -bool true

# Finder: mostrar status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Dock: tamanho dos ícones
# defaults write com.apple.dock tilesize -int 48

# Dock: auto-hide
# defaults write com.apple.dock autohide -bool true

# Screenshots: guardar no Desktop
defaults write com.apple.screencapture location -string "$HOME/Desktop"

# Screenshots: formato PNG
defaults write com.apple.screencapture type -string "png"

# Teclado: repetição rápida
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Pasta "desktop de arquivo" — destino de bin/desktop-tidy.sh
mkdir -p "$HOME/Documents/Working Info"

echo "  Preferências macOS aplicadas. Algumas podem precisar de logout/restart."
