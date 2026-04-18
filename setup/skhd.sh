#!/bin/bash
# setup/skhd.sh — Iniciar/reiniciar o serviço skhd para aplicar o skhdrc
# Requer: skhd instalado (via Brewfile) e permissão "Acessibilidade" no macOS
set -euo pipefail

if ! command -v skhd &>/dev/null; then
    echo "  skhd não instalado, a saltar"
    exit 0
fi

if brew services list 2>/dev/null | awk '{print $1, $2}' | grep -q "^skhd started$"; then
    echo "  skhd: a reiniciar serviço (aplicar nova config)..."
    brew services restart skhd >/dev/null
else
    echo "  skhd: a iniciar serviço..."
    brew services start skhd >/dev/null
fi

echo "  NOTA: na primeira execução, autorizar skhd em"
echo "        Definições → Privacidade e Segurança → Acessibilidade"
