# ~/.zprofile — Executado em login shells
# Inicialização do Homebrew (uma única vez, herdada por shells filhas)

if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi
