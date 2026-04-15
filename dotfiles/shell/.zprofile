# ~/.zprofile — Executado em login shells
# Inicialização do Homebrew para garantir que está disponível em todos os contextos

if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi
