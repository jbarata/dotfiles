#!/bin/bash
# setup/whisperx.sh — venv isolado para whisperx (diarização).
#
# whisperx = faster-whisper (ASR via CTranslate2) + pyannote.audio
# (diarização) + wav2vec2 (alinhamento word-level). Saída SRT/TXT com
# `[SPEAKER_00] / [SPEAKER_01] / …` por segmento.
#
# Não descarregamos modelos no setup — whisperx fá-lo lazy ao primeiro
# uso, para `~/.cache/huggingface/`. Total aproximado: ~3 GB (large-v3
# em CTranslate2) + ~500 MB (pyannote). Formatos diferentes do `.bin`
# ggml usado pelo whisper.cpp; coexistem em caches separadas.
#
# Pré-requisitos manuais (uma vez):
#   1. Conta huggingface.co + Access Token (read scope)
#   2. Aceitar T&C em:
#        https://huggingface.co/pyannote/speaker-diarization-community-1
#        https://huggingface.co/pyannote/segmentation-3.0
#      (Versões antigas de whisperx usavam speaker-diarization-3.1; o
#       default actual é o community-1, mais permissivo e activo.)
#   3. Guardar token no 1Password em op://Private/HuggingFace/token
#      (ou ajustar WHISPERX_HF_TOKEN_OP_REF no shell/.exports)
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
WHISPERX_VENV="$HOME/.local/share/whisperx-venv"

# --- 1. Python 3.11 (mesmo pin do venv Core ML) -------------------------
# whisperx + pyannote + torch são picuinhas com versões; 3.11 é o sweet
# spot que cobre todas as combinações testadas pelo upstream.
PYTHON=""
for candidate in python3.11 python3.12; do
    if command -v "$candidate" >/dev/null 2>&1; then
        PYTHON="$candidate"
        break
    fi
done

if [[ -z "$PYTHON" ]]; then
    echo "✗ Python 3.11/3.12 em falta. Instala com: brew install python@3.11" >&2
    exit 1
fi

echo "  Python: $(command -v "$PYTHON") ($($PYTHON --version))"

# --- 2. Recriar venv se foi feito com outro Python (ex.: brew upgrade) --
if [[ -d "$WHISPERX_VENV" && ! -x "$WHISPERX_VENV/bin/$PYTHON" ]]; then
    echo "  Venv existente com outro Python — a recriar..."
    rm -rf "$WHISPERX_VENV"
fi

if [[ ! -d "$WHISPERX_VENV" ]]; then
    echo "  A criar venv em $WHISPERX_VENV..."
    "$PYTHON" -m venv "$WHISPERX_VENV"
fi

# --- 3. Instalar whisperx + deps ----------------------------------------
# Activamos para subshell — não polui o env do utilizador. Pip está
# silenciado a não ser que falhe.
# shellcheck disable=SC1091
source "$WHISPERX_VENV/bin/activate"

echo "  pip upgrade..."
pip install --quiet --upgrade pip

echo "  pip install whisperx (~2 GB de torch + ctranslate2 + pyannote, demora alguns minutos)..."
# whisperx puxa torch, faster-whisper, pyannote.audio, ctranslate2 como
# transitivas — não pinamos nenhuma para deixar o resolver do whisperx
# escolher combinações testadas.
pip install --quiet whisperx

deactivate

# --- 4. Verificar binário -----------------------------------------------
if [[ ! -x "$WHISPERX_VENV/bin/whisperx" ]]; then
    echo "✗ whisperx não foi instalado em $WHISPERX_VENV/bin/whisperx" >&2
    exit 1
fi

echo ""
echo "  WhisperX pronto."
echo "    Venv:    $WHISPERX_VENV"
echo "    Comando: transcribe-diarize <ficheiro>"
echo ""
echo "  Pré-requisitos manuais (se ainda não fizeste):"
echo "    1. huggingface.co → criar conta + Access Token (Settings → Access Tokens)"
echo "    2. Aceitar T&C em:"
echo "         https://huggingface.co/pyannote/speaker-diarization-community-1"
echo "         https://huggingface.co/pyannote/segmentation-3.0"
echo "    3. 1Password → vault Private → criar item 'HuggingFace' com campo 'token'"
echo ""
echo "  Modelos pyannote + large-v3 (CTranslate2) descarregam ao 1º uso (~3.5 GB)."
