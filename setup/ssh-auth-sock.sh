#!/bin/bash
# setup/ssh-auth-sock.sh — Aponta SSH_AUTH_SOCK das apps GUI para o agente
# do 1Password, persistente entre reboots.
#
# Problema que resolve: apps GUI (ex.: Fork) não respeitam o ~/.ssh/config
# nem herdam o SSH_AUTH_SOCK definido ad-hoc com `launchctl setenv` no
# terminal (macOS Sequoia não propaga para apps lançadas via LaunchServices).
#
# Solução: um LaunchAgent que corre no login e define a variável via
# `launchctl setenv` — esse valor fica disponível para qualquer app aberta
# a partir desse momento.
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
SRC="$DOTFILES/launchd/com.mimes.ssh-auth-sock.plist"
DST="$HOME/Library/LaunchAgents/com.mimes.ssh-auth-sock.plist"
SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

mkdir -p "$(dirname "$DST")"

SYMLINK_OK=false
[[ -L "$DST" && "$(readlink "$DST")" == "$SRC" ]] && SYMLINK_OK=true

AGENT_LOADED=false
launchctl list 2>/dev/null | grep -q com.mimes.ssh-auth-sock && AGENT_LOADED=true

CURRENT_SOCK=$(launchctl getenv SSH_AUTH_SOCK 2>/dev/null || true)

if $SYMLINK_OK && $AGENT_LOADED && [[ "$CURRENT_SOCK" == "$SOCK" ]]; then
    echo "  SSH_AUTH_SOCK: já configurado (LaunchAgent activo)"
    exit 0
fi

# Symlink do plist
if ! $SYMLINK_OK; then
    [[ -e "$DST" ]] && rm "$DST"
    ln -s "$SRC" "$DST"
    echo "  Link: $DST → $SRC"
fi

# (Re)carregar o agent para apanhar alterações ao plist
if $AGENT_LOADED; then
    launchctl unload "$DST" 2>/dev/null || true
fi
launchctl load "$DST"

# Definir também na sessão actual (o agent já o faz a partir do próximo
# login; isto evita obrigar a logout/login agora)
launchctl setenv SSH_AUTH_SOCK "$SOCK"

echo "  SSH_AUTH_SOCK → 1Password agent (persistente via LaunchAgent)"
