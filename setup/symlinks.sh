#!/bin/bash
# setup/symlinks.sh — Criar symlinks com GNU Stow + links manuais para ~/Library/
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
BACKUP_DIR="$HOME/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# --- Função auxiliar para symlinks manuais ---
link_config() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        mkdir -p "$BACKUP_DIR"
        local backup_name
        backup_name=$(echo "$dst" | sed "s|$HOME/||; s|/|__|g")
        mv "$dst" "$BACKUP_DIR/$backup_name"
        echo "  Backup: $dst → $BACKUP_DIR/$backup_name"
    fi
    ln -sf "$src" "$dst"
    echo "  Link: $dst → $src"
}

# --- GNU Stow para ficheiros na home (~) ---
# --no-folding: nunca substitui directórios por symlinks (evita conflitos com .ssh/, .config/)
cd "$DOTFILES"

echo "  Stow: git..."
stow --no-folding -t "$HOME" git

echo "  Stow: shell..."
stow --no-folding -t "$HOME" shell

echo "  Stow: ssh..."
stow --no-folding -t "$HOME" ssh

echo "  Stow: ghostty..."
stow --no-folding -t "$HOME" ghostty

# --- VS Code (~/Library/Application Support/Code/User/) ---
VSCODE_USER="$HOME/Library/Application Support/Code/User"
echo "  VS Code settings..."
link_config "$DOTFILES/vscode/settings.json" "$VSCODE_USER/settings.json"
link_config "$DOTFILES/vscode/keybindings.json" "$VSCODE_USER/keybindings.json"

mkdir -p "$VSCODE_USER/snippets"
for snippet in "$DOTFILES/vscode/snippets/"*.json; do
    [[ -f "$snippet" ]] && link_config "$snippet" "$VSCODE_USER/snippets/$(basename "$snippet")"
done

# --- Claude Code (~/.claude/) ---
echo "  Claude Code settings..."
mkdir -p "$HOME/.claude"
link_config "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
link_config "$DOTFILES/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
