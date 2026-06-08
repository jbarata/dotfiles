#!/bin/bash
# setup/symlinks.sh — Criar symlinks com GNU Stow + links manuais para ~/Library/
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
BACKUP_DIR="$HOME/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# --- Função auxiliar para symlinks manuais ---
link_config() {
    local src="$1" dst="$2"

    # Resolver src para path absoluto (evitar loops)
    src=$(cd "$(dirname "$src")" 2>/dev/null && pwd)/$(basename "$src")

    # Garantir que o parent do dst existe antes de o resolvermos
    mkdir -p "$(dirname "$dst")"

    # Resolver parents para path canónico (seguindo symlinks) — detecta o caso
    # em que o parent do dst é um symlink para dentro do source tree, o que
    # faria com que operações sobre $dst afectassem o próprio ficheiro do repo.
    local src_parent_real dst_parent_real
    src_parent_real=$(cd "$(dirname "$src")" && pwd -P)
    dst_parent_real=$(cd "$(dirname "$dst")" && pwd -P)

    if [[ "$dst_parent_real" == "$src_parent_real" ]]; then
        echo "  AVISO: $(dirname "$dst") resolve para $(dirname "$src")"
        echo "         (parent é symlink para o repo) — a saltar $(basename "$dst")."
        echo "         Remove o symlink do directório e corre de novo:"
        echo "           rm \"$(dirname "$dst")\" && mkdir -p \"$(dirname "$dst")\""
        return 0
    fi

    # Recusa criar symlink circular (src == dst)
    if [[ "$src" == "$dst" ]]; then
        echo "  ERRO: src e dst iguais ($src), a saltar"
        return 0
    fi

    # Se dst já é o symlink correcto, nada a fazer
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        return 0
    fi

    # Backup se for ficheiro real
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        mkdir -p "$BACKUP_DIR"
        local backup_name
        backup_name=$(echo "$dst" | sed "s|$HOME/||; s|/|__|g")
        mv "$dst" "$BACKUP_DIR/$backup_name"
        echo "  Backup: $dst → $BACKUP_DIR/$backup_name"
    fi

    # Remover symlinks errados ou broken
    if [[ -L "$dst" ]]; then
        rm "$dst"
    fi

    ln -s "$src" "$dst"
    echo "  Link: $dst → $src"
}

# --- GNU Stow para ficheiros directos na home (~) ---
# --no-folding: nunca substitui directórios por symlinks
cd "$DOTFILES"

echo "  Stow: git..."
stow --no-folding -t "$HOME" git

echo "  Stow: shell..."
stow --no-folding -t "$HOME" shell

echo "  Stow: vim..."
stow --no-folding -t "$HOME" vim

# --- SSH e Ghostty: usar link_config (stow não lida bem com dirs existentes como ~/.ssh) ---
echo "  SSH config..."
link_config "$DOTFILES/ssh/.ssh/config" "$HOME/.ssh/config"

echo "  Ghostty config..."
link_config "$DOTFILES/ghostty/.config/ghostty/config" "$HOME/.config/ghostty/config"

echo "  skhd config..."
link_config "$DOTFILES/skhd/.config/skhd/skhdrc" "$HOME/.config/skhd/skhdrc"

echo "  Starship config..."
link_config "$DOTFILES/starship/.config/starship.toml" "$HOME/.config/starship.toml"

# Ghostty themes (linka todos os ficheiros na pasta themes)
if [[ -d "$DOTFILES/ghostty/.config/ghostty/themes" ]]; then
    for theme in "$DOTFILES/ghostty/.config/ghostty/themes/"*; do
        [[ -f "$theme" ]] && link_config "$theme" "$HOME/.config/ghostty/themes/$(basename "$theme")"
    done
fi

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
