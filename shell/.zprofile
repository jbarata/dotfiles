# ~/.zprofile — Executado em login shells
# Inicialização do Homebrew (uma única vez, herdada por shells filhas)

if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Locale
# A região do macOS é Portugal mas o idioma primário é Inglês → o combo
# en_PT.UTF-8 não existe, por isso os terminais (Ghostty/iTerm/Terminal.app)
# caem para a 2ª língua preferida e injetam LANG=LC_ALL=pt_PT.UTF-8.
# Queremos mensagens (git, etc.) em inglês mas manter formatos PT (datas, €).
unset LC_ALL                      # injetado pelo terminal; sobrepõe-se a tudo
export LC_MESSAGES=en_US.UTF-8    # só as mensagens em inglês; LANG fica pt_PT
