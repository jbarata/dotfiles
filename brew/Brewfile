# Brewfile — Dependências partilhadas entre todas as máquinas

# Taps
tap "koekeishiya/formulae"   # skhd

# CLI tools
brew "git"
brew "gh"                    # GitHub CLI
brew "stow"                  # Symlink farm manager para dotfiles
brew "gcalcli"               # Google Calendar CLI (usado pelo focus.widget)
brew "fzf"                   # Fuzzy finder (Ctrl+R, Ctrl+T)
brew "fd"                    # find alternativo (usado pelo fzf)
brew "koekeishiya/formulae/skhd" # Hotkey daemon (shortcuts → URLs/apps)
brew "cmake"                 # Build system (whisper.cpp, etc.)
brew "sdl2"                  # Audio capture lib (whisper-stream)
brew "ffmpeg"                # Conversão áudio/vídeo (transcribe.sh: m4a/mp3 → 16 kHz wav)
brew "python@3.11"           # Pinned para o venv de conversão Core ML (whisper.cpp):
                             # ane_transformers prende torch 2.x → Python ≤3.12.
                             # 3.11 maximiza compatibilidade com torch+coremltools.

# Zsh plugins
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

# Fonts
cask "font-jetbrains-mono"

# GUI apps
cask "1password"
cask "1password-cli"         # 1Password CLI (op) — instalado como cask
cask "ghostty"
cask "iterm2"
cask "visual-studio-code"
cask "ubersicht"
cask "claude"
cask "rectangle"             # Window manager (atalhos de Halfs/Thirds/Quarters)
