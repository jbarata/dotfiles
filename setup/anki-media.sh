#!/bin/bash
# setup/anki-media.sh — Copiar anki/media/*.{png,jpg,jpeg,gif,svg,webp,mp3,m4a,wav}
# para a pasta collection.media do Anki, para que o `<img src>` dos cartões
# `html:true` em anki/cards.txt funcione no Anki desktop.
#
# Override do perfil: ANKI_PROFILE=outroPerfil bash setup/anki-media.sh
#
# Idempotente (usa rsync --update); skip silencioso se Anki ainda não foi
# lançado (a pasta do perfil só aparece depois do primeiro run).
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
ANKI_PROFILE="${ANKI_PROFILE:-User 1}"
SRC="$DOTFILES/anki/media"
DEST="$HOME/Library/Application Support/Anki2/$ANKI_PROFILE/collection.media"

if [[ ! -d "$SRC" ]]; then
    echo "  $SRC não existe, a saltar"
    exit 0
fi

if [[ ! -d "$DEST" ]]; then
    echo "  Anki profile \"$ANKI_PROFILE\" não inicializado em $DEST"
    echo "  → lançar Anki uma vez (cria o perfil) e voltar a correr este script,"
    echo "    ou definir ANKI_PROFILE=<nome> se o perfil tem outro nome"
    exit 0
fi

# Excluir o README e qualquer ficheiro oculto; copiar tipos comuns.
COPIED=$(rsync -a --update \
    --include='*.png' --include='*.jpg' --include='*.jpeg' \
    --include='*.gif' --include='*.svg' --include='*.webp' \
    --include='*.mp3' --include='*.m4a' --include='*.wav' \
    --exclude='*' \
    --itemize-changes \
    "$SRC/" "$DEST/" | wc -l | tr -d ' ')

echo "  $COPIED ficheiro(s) copiado(s)/actualizado(s) em $DEST"
