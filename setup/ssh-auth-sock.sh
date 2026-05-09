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
#
# Em macOS Sequoia/Tahoe `launchctl load` é legacy e por vezes devolve
# "Load failed: 5: Input/output error" silenciosamente (exit 0). Usamos
# `launchctl bootstrap`/`bootout` que dão erros úteis e estado fiável.
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
SRC="$DOTFILES/launchd/com.mimes.ssh-auth-sock.plist"
DST="$HOME/Library/LaunchAgents/com.mimes.ssh-auth-sock.plist"
SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

UID_NUM=$(id -u)
DOMAIN="gui/$UID_NUM"
LABEL="com.mimes.ssh-auth-sock"

mkdir -p "$(dirname "$DST")"

agent_active() {
    launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1
}

SYMLINK_OK=false
[[ -L "$DST" && "$(readlink "$DST")" == "$SRC" ]] && SYMLINK_OK=true

CURRENT_SOCK=$(launchctl getenv SSH_AUTH_SOCK 2>/dev/null || true)

if $SYMLINK_OK && agent_active && [[ "$CURRENT_SOCK" == "$SOCK" ]]; then
    echo "  SSH_AUTH_SOCK: já configurado (LaunchAgent activo)"
    exit 0
fi

# Symlink do plist
if ! $SYMLINK_OK; then
    [[ -e "$DST" ]] && rm "$DST"
    ln -s "$SRC" "$DST"
    echo "  Link: $DST → $SRC"
fi

# (Re)carregar via API moderna — bootout limpa estado anterior, bootstrap
# carrega de novo. Tolerar falhas silenciosamente: o symlink em
# ~/Library/LaunchAgents/ é suficiente para o launchd carregar no próximo
# login mesmo que a injecção imediata falhe.
if agent_active; then
    launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
fi

LOAD_ERR=""
if ! LOAD_ERR=$(launchctl bootstrap "$DOMAIN" "$DST" 2>&1); then
    # Fallback para `load` (macOS antigos) só se bootstrap não estiver disponível
    LOAD_ERR=$(launchctl load "$DST" 2>&1 || true)
fi

# Definir na sessão actual (vale para apps abertas a partir do terminal,
# evita logout/login)
launchctl setenv SSH_AUTH_SOCK "$SOCK"

if agent_active; then
    echo "  SSH_AUTH_SOCK → 1Password agent (LaunchAgent activo)"
else
    echo "  SSH_AUTH_SOCK → 1Password agent (definido nesta sessão; LaunchAgent activa no próximo login)"
    if [[ -n "$LOAD_ERR" ]]; then
        echo "  (launchctl: $LOAD_ERR)"
    fi
fi
