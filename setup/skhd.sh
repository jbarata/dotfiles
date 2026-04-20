#!/bin/bash
# setup/skhd.sh — Instalar/iniciar/reiniciar o serviço skhd para aplicar o skhdrc
# Requer: skhd instalado (via Brewfile) e permissão "Acessibilidade" no macOS
#
# skhd gere o seu próprio launchd agent (~/Library/LaunchAgents/com.koekeishiya.skhd.plist)
# via --install-service / --start-service / --restart-service — não usa brew services.
set -euo pipefail

if ! command -v skhd &>/dev/null; then
    echo "  skhd não instalado, a saltar"
    exit 0
fi

PLIST="$HOME/Library/LaunchAgents/com.koekeishiya.skhd.plist"
FIRST_INSTALL=false

if [[ ! -f "$PLIST" ]]; then
    echo "  skhd: a instalar launchd agent..."
    skhd --install-service >/dev/null
    FIRST_INSTALL=true
fi

if launchctl list 2>/dev/null | grep -q "com.koekeishiya.skhd"; then
    echo "  skhd: a reiniciar serviço (aplicar nova config)..."
    skhd --restart-service >/dev/null
else
    echo "  skhd: a iniciar serviço..."
    skhd --start-service >/dev/null
fi

if $FIRST_INSTALL; then
    echo "  NOTA: na primeira execução, autorizar skhd em"
    echo "        Definições → Privacidade e Segurança → Acessibilidade"
fi
