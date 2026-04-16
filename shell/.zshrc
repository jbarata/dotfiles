# ~/.zshrc — Configuração principal do Zsh
# Gerido por: https://github.com/mimes70/dotfiles

# =========================================================
# 1. PATH (limpo + sem duplicados)
# =========================================================
typeset -U path
path=(
    $HOME/.local/bin
    $HOME/.bin
    $HOME/bin
    $HOME/Work/cmd-line-importer
    $path
)
export PATH

# =========================================================
# 2. Deteção de arquitetura (Intel vs Apple Silicon)
# =========================================================
if [[ "$(uname -m)" == "arm64" ]]; then
    export HOMEBREW_PREFIX="/opt/homebrew"
    export MACHINE_TYPE="macbook"
else
    export HOMEBREW_PREFIX="/usr/local"
    export MACHINE_TYPE="imac"
fi

# =========================================================
# 3. Configurações modulares
# =========================================================
[[ -f ~/.aliases ]] && source ~/.aliases
[[ -f ~/.exports ]] && source ~/.exports

# Overrides específicos da máquina
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
MACHINE_CONFIG="$DOTFILES/machine/${MACHINE_TYPE}.sh"
[[ -f "$MACHINE_CONFIG" ]] && source "$MACHINE_CONFIG"

# =========================================================
# 4. Histórico (smart + IDE-like)
# =========================================================
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE

# =========================================================
# 5. Opções Zsh
# =========================================================
setopt AUTO_CD
setopt NO_BEEP
setopt INTERACTIVE_COMMENTS
setopt PROMPT_SUBST

# =========================================================
# 6. Completions (cacheado — grande speedup)
# =========================================================
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# =========================================================
# 7. Prompt (ultra fast, sem frameworks)
# =========================================================
autoload -Uz vcs_info
precmd() { vcs_info 2>/dev/null }
zstyle ':vcs_info:git:*' formats '(%b)'
PROMPT='%n@%m %F{cyan}%1~%f %F{magenta}${vcs_info_msg_0_}%f%# '

# =========================================================
# 8. Vi mode (turbo)
# =========================================================
bindkey -v
export KEYTIMEOUT=1

# Cursor diferente por modo
zle-keymap-select() {
    [[ $KEYMAP == vicmd ]] && print -n "\e[1 q" || print -n "\e[5 q"
}
zle -N zle-keymap-select

zle-line-init() {
    print -n "\e[5 q"
}
zle -N zle-line-init

# Navegação em modo insert (atalhos úteis)
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^W' backward-kill-word

# =========================================================
# 9. NVM (lazy loading + project-aware)
# =========================================================
nvm() {
    unset -f nvm node npm npx
    source "$NVM_DIR/nvm.sh"
    nvm "$@"
}

autoload -Uz add-zsh-hook

__node_loaded=0

load_node() {
    [[ $__node_loaded -eq 1 ]] && return
    __node_loaded=1
    [[ -f .nvmrc ]] && nvm use >/dev/null 2>&1 || nvm use --lts >/dev/null 2>&1
}

add-zsh-hook chpwd load_node

# =========================================================
# 10. fzf (fuzzy search)
# =========================================================
if command -v fzf >/dev/null 2>&1; then
    if [[ -f $HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh ]]; then
        source $HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh
    fi
else
    bindkey '^R' history-incremental-search-backward
fi

# =========================================================
# 11. COB (lazy init)
# =========================================================
if command -v cob >/dev/null 2>&1; then
    eval "$(cob init -)"
fi
[[ -f "$HOME/.cob-cli/completion.sh" ]] && source "$HOME/.cob-cli/completion.sh"

# =========================================================
# 12. Autosuggestions + Syntax highlighting
# =========================================================
# brew install zsh-autosuggestions zsh-syntax-highlighting
if [[ -f $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Syntax highlighting deve ser o ÚLTIMO source
if [[ -f $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# =========================================================
# 13. Funções
# =========================================================
rtmux() {
    local server=$1
    shift
    autossh -M 0 -t "$server" "$@" \
        "tmux -qu has -t mimes && tmux -qu attach -t mimes || tmux -qu new -s mimes"
}

listening() {
    if [[ $# -eq 0 ]]; then
        sudo lsof -iTCP -sTCP:LISTEN -n -P +c 0
    else
        sudo lsof -iTCP -sTCP:LISTEN -n -P +c 0 | grep -i --color "$1"
    fi
}

zsh_startup_time() {
    for i in {1..5}; do
        time zsh -i -c exit
    done
}
