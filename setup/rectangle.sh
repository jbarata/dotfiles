#!/bin/bash
# setup/rectangle.sh — Aplicar config do Rectangle (window manager) versionada
# Requer: Rectangle instalado (via Brewfile cask) e permissão "Acessibilidade"
#
# A config do Rectangle vive em ~/Library/Preferences/com.knollsoft.Rectangle.plist
# (NSUserDefaults). O ficheiro versionado em rectangle/RectangleConfig.json é o
# export "Import/Export → Export to file" da UI; aqui é convertido para plist e
# aplicado via `defaults import`. Os defaults do Rectangle já cobrem a maioria
# das teclas da cheat sheet — este passo serve para fixar overrides locais.
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
CONFIG_JSON="$DOTFILES/rectangle/RectangleConfig.json"
DOMAIN="com.knollsoft.Rectangle"

if ! [[ -d "/Applications/Rectangle.app" ]]; then
    echo "  Rectangle não instalado em /Applications, a saltar"
    exit 0
fi

if [[ ! -f "$CONFIG_JSON" ]]; then
    echo "  rectangle/RectangleConfig.json não existe — a saltar import."
    echo "  Para versionar a tua config: Rectangle → Settings → Import/Export"
    echo "  → Export to file e gravar em $CONFIG_JSON"
    exit 0
fi

TMP_PLIST=$(mktemp -t rectangle-config-XXXXXX).plist
trap 'rm -f "$TMP_PLIST"' EXIT

if ! plutil -convert binary1 -o "$TMP_PLIST" "$CONFIG_JSON" 2>/dev/null; then
    echo "  !! Falhou converter $CONFIG_JSON para plist (formato inválido?)"
    exit 1
fi

echo "  A importar config Rectangle..."
defaults import "$DOMAIN" "$TMP_PLIST"

# Reiniciar Rectangle para aplicar (lê NSUserDefaults só no arranque)
if pgrep -x Rectangle >/dev/null; then
    osascript -e 'tell application "Rectangle" to quit' 2>/dev/null || true
    sleep 1
fi
open -ga Rectangle

echo "  Rectangle: config importada e relançado"
echo "  NOTA: na primeira execução, autorizar Rectangle em"
echo "        Definições → Privacidade e Segurança → Acessibilidade"
