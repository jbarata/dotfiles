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

# --- 1b. Verificar Command Line Tools (compilação de fórmulas como skhd) ---
echo "==> A verificar Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    echo "!! Command Line Tools não instaladas."
    echo "   Corre: sudo xcode-select --install"
    exit 1
fi
CLT_SDK=$(xcrun --show-sdk-version 2>/dev/null || true)
if [[ -n "$CLT_SDK" ]]; then
    MACOS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
    SDK_MAJOR=${CLT_SDK%%.*}
    if [[ "$SDK_MAJOR" -lt "$MACOS_MAJOR" ]]; then
        echo "!! Command Line Tools desatualizadas (SDK $CLT_SDK, macOS $MACOS_MAJOR)."
        echo "   Instala via Software Update em System Settings, ou:"
        echo "     sudo rm -rf /Library/Developer/CommandLineTools"
        echo "     sudo xcode-select --install"
        echo "   Alternativa: https://developer.apple.com/download/all/"
        exit 1
    fi
    echo "   CLT SDK $CLT_SDK (macOS $MACOS_MAJOR) ✓"
else
    echo "   CLT presente (SDK não determinado via xcrun) ✓"
fi

# --- 2. Instalar dependências via Brewfile ---
echo "==> A instalar pacotes Homebrew..."
run brew bundle --file="$DOTFILES/brew/Brewfile" || true
if [[ -f "$DOTFILES/brew/Brewfile.$MACHINE" ]]; then
    echo "==> A instalar pacotes específicos ($MACHINE)..."
    run brew bundle --file="$DOTFILES/brew/Brewfile.$MACHINE" || true
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

# Categorizar ficheiros locais: idênticos ao repo, diferentes, novos, ou symlinks stale
STALE_LINKS=()
IDENTICAL_FILES=()
DIFFERENT_FILES=()
NEW_FILES=()
for pair in "${PAIRS[@]}"; do
    local_f="${pair%%|*}"
    repo_f="${pair##*|}"
    if [[ -L "$local_f" ]]; then
        # Symlink — resolver alvo (stow cria symlinks relativos) e comparar
        # contra o path absoluto do repo
        current_target=$(readlink "$local_f")
        if [[ "$current_target" != /* ]]; then
            current_target="$(cd "$(dirname "$local_f")" && cd "$(dirname "$current_target")" 2>/dev/null && pwd)/$(basename "$current_target")"
        fi
        if [[ "$current_target" != "$repo_f" ]]; then
            STALE_LINKS+=("$local_f|$current_target")
        fi
    elif [[ -e "$local_f" ]]; then
        if [[ -f "$repo_f" ]] && diff -q "$local_f" "$repo_f" &>/dev/null; then
            IDENTICAL_FILES+=("$local_f")
        elif [[ -f "$repo_f" ]]; then
            DIFFERENT_FILES+=("$local_f|$repo_f")
        else
            NEW_FILES+=("$local_f")
        fi
    fi
done

HAS_CONFLICTS=false
if [[ ${#DIFFERENT_FILES[@]} -gt 0 || ${#NEW_FILES[@]} -gt 0 || ${#STALE_LINKS[@]} -gt 0 ]]; then
    HAS_CONFLICTS=true
fi

if $HAS_CONFLICTS; then
    # --- 4a. Mostrar diferenças e symlinks stale ---
    echo "==> Diferenças entre ficheiros actuais e repo:"
    echo ""
    for pair in "${DIFFERENT_FILES[@]}"; do
        local_f="${pair%%|*}"
        repo_f="${pair##*|}"
        DIFF_OUTPUT=$(diff "$local_f" "$repo_f" 2>/dev/null || true)
        echo "--- $local_f vs $repo_f ---"
        echo "$DIFF_OUTPUT"
        echo ""
    done
    for f in "${NEW_FILES[@]}"; do
        echo "  $f — novo (não existe no repo)"
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
        for pair in "${DIFFERENT_FILES[@]}"; do
            echo "  [dry-run] backup ${pair%%|*} → $BACKUP_DIR/"
        done
        for f in "${NEW_FILES[@]}"; do
            echo "  [dry-run] backup $f → $BACKUP_DIR/"
        done

        if [[ ${#STALE_LINKS[@]} -gt 0 ]]; then
            for stale in "${STALE_LINKS[@]}"; do
                link="${stale%%|*}"
                echo "  [dry-run] remove symlink $link"
            done
        fi
    else
        mkdir -p "$BACKUP_DIR"
        for pair in "${DIFFERENT_FILES[@]}"; do
            local_f="${pair%%|*}"
            cp "$local_f" "$BACKUP_DIR/$(basename "$local_f")"
            rm "$local_f"
            echo "  Backup: $local_f"
        done
        for f in "${NEW_FILES[@]}"; do
            cp "$f" "$BACKUP_DIR/$(basename "$f")"
            rm "$f"
            echo "  Backup: $f"
        done
        if [[ ${#STALE_LINKS[@]} -gt 0 ]]; then
            for stale in "${STALE_LINKS[@]}"; do
                link="${stale%%|*}"
                target="${stale##*|}"
                echo "$link → $target" >> "$BACKUP_DIR/stale-symlinks.log"
                rm "$link"
                echo "  Removed stale symlink: $link"
            done
        fi
        echo "  Guardado em: $BACKUP_DIR/"
    fi
fi

# Ficheiros idênticos ao repo: remover sem prompt (conteúdo já está no repo)
if [[ ${#IDENTICAL_FILES[@]} -gt 0 ]]; then
    echo "==> A remover ficheiros idênticos ao repo (para criar symlinks):"
    for f in "${IDENTICAL_FILES[@]}"; do
        if $DRY_RUN; then
            echo "  [dry-run] remove $f"
        else
            rm "$f"
            echo "  Removido: $f"
        fi
    done
elif ! $HAS_CONFLICTS; then
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

# --- 9b2. Importar config Rectangle (window manager) ---
if [[ -f "$DOTFILES/setup/rectangle.sh" ]]; then
    echo "==> A configurar Rectangle..."
    if $DRY_RUN; then
        echo "  [dry-run] defaults import com.knollsoft.Rectangle (se rectangle/RectangleConfig.json existir)"
    else
        bash "$DOTFILES/setup/rectangle.sh"
    fi
fi

# --- 9b3. Copiar media do Anki para o perfil ---
if [[ -f "$DOTFILES/setup/anki-media.sh" ]]; then
    echo "==> A copiar media do Anki..."
    if $DRY_RUN; then
        echo "  [dry-run] rsync anki/media/* → ~/Library/.../Anki2/User 1/collection.media/"
    else
        bash "$DOTFILES/setup/anki-media.sh"
    fi
fi

# --- 9c. SSH_AUTH_SOCK para apps GUI (Fork, etc.) → 1Password ---
if [[ -f "$DOTFILES/setup/ssh-auth-sock.sh" ]]; then
    echo "==> A configurar SSH_AUTH_SOCK (1Password) para apps GUI..."
    if $DRY_RUN; then
        echo "  [dry-run] symlink LaunchAgent + launchctl load + setenv"
    else
        bash "$DOTFILES/setup/ssh-auth-sock.sh"
    fi
fi

# --- 9d. CLIs COB (cob-cli@beta + cob-md-to-pdf + cob-aia linkados) ---
if [[ -f "$DOTFILES/setup/cob-tools.sh" ]]; then
    echo "==> A instalar CLIs COB..."
    if $DRY_RUN; then
        echo "  [dry-run] npm install -g cob-cli@beta"
        echo "  [dry-run] git clone cob-md-to-pdf → \$HOME/.local/src/ && npm i && npm link"
        echo "  [dry-run] git clone cob-aia → \$HOME/.local/src/ && npm i && npm link"
    else
        bash "$DOTFILES/setup/cob-tools.sh"
    fi
fi

# --- 9e. Whisper.cpp (ditado por voz, streaming) ---
if [[ -f "$DOTFILES/setup/whisper.sh" ]]; then
    echo "==> A instalar whisper.cpp..."
    if $DRY_RUN; then
        echo "  [dry-run] git clone whisper.cpp → \$HOME/.local/src/"
        echo "  [dry-run] cmake build (SDL2 + Core ML em arm64)"
        echo "  [dry-run] download modelo ggml-medium.bin (~1.5 GB, streaming dictate)"
        echo "  [dry-run] download modelo ggml-large-v3.bin (~3 GB, batch transcribe)"
        if [[ "$ARCH" == "arm64" ]]; then
            echo "  [dry-run] gerar Core ML encoder em venv (5–10 min, ~2 GB deps)"
        fi
    else
        bash "$DOTFILES/setup/whisper.sh"
    fi
fi

# --- 9f. WhisperX (transcrição + diarização para reuniões/diálogos) ---
if [[ -f "$DOTFILES/setup/whisperx.sh" ]]; then
    echo "==> A instalar whisperx (diarização)..."
    if $DRY_RUN; then
        echo "  [dry-run] criar venv ~/.local/share/whisperx-venv (~2 GB de torch + deps)"
        echo "  [dry-run] modelos pyannote + large-v3 CT2 (~3.5 GB) descarregam ao 1º uso"
        echo "  [dry-run] requer HF token manual em op://Private/HuggingFace/token"
    else
        bash "$DOTFILES/setup/whisperx.sh"
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
