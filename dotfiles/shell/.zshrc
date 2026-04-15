# ~/.zshrc — Configuração principal do Zsh
# Gerido por: https://github.com/mimes70/dotfiles

# --- Deteção de arquitetura (Intel vs Apple Silicon) ---
if [[ "$(uname -m)" == "arm64" ]]; then
    export HOMEBREW_PREFIX="/opt/homebrew"
    export MACHINE_TYPE="macbook"
else
    export HOMEBREW_PREFIX="/usr/local"
    export MACHINE_TYPE="imac"
fi

# Inicializar Homebrew
eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"

# --- Configurações modulares ---
[[ -f ~/.aliases ]] && source ~/.aliases
[[ -f ~/.exports ]] && source ~/.exports

# --- Overrides específicos da máquina ---
MACHINE_CONFIG="$HOME/.dotfiles/machine/${MACHINE_TYPE}.sh"
[[ -f "$MACHINE_CONFIG" ]] && source "$MACHINE_CONFIG"

# --- 1Password SSH Agent ---
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# --- Histórico ---
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# --- Completions ---
autoload -Uz compinit && compinit

# --- Prompt (personalizar conforme preferência) ---
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%F{cyan}%1~%f%F{magenta}${vcs_info_msg_0_}%f %# '
