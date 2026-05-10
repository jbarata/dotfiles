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

# --- 1b. Patch pyexpat se libexpat do sistema não tiver os símbolos novos ---
# macOS 26.0–26.2 (Tahoe pré-26.3): /usr/lib/libexpat.1.dylib do Apple é
# antigo e não exporta _XML_SetAllocTrackerActivationThreshold. Os pyexpat.so
# das bottles Homebrew Python (3.11+) ligam contra essa libexpat por nome
# directo e falham `import pyexpat` em runtime — o que parte pip, requests,
# whisperx, etc. Fix oficial (ver Homebrew/homebrew-core#277330): apontar
# pyexpat.so ao libexpat do Homebrew (`brew install expat` → ≥2.7) via
# install_name_tool + re-assinar (codesign ad-hoc) por causa do hardened
# runtime. Apple corrigiu /usr/lib em macOS 26.3+; o patch é idempotente
# (skip quando `import pyexpat` já passa).
fix_pyexpat_if_broken() {
    local py="$1"
    if "$py" -c "import pyexpat" 2>/dev/null; then
        return 0
    fi

    local err
    err=$("$py" -c "import pyexpat" 2>&1 || true)
    if ! echo "$err" | grep -q "_XML_SetAllocTrackerActivationThreshold"; then
        echo "  pyexpat falha com erro inesperado:" >&2
        echo "$err" >&2
        return 1
    fi

    echo "  pyexpat partido (libexpat do macOS sem símbolo novo, conhecido em 26.0–26.2)"
    echo "  A aplicar patch: install_name_tool → expat do Homebrew..."

    if ! command -v brew &>/dev/null; then
        echo "  ✗ brew não disponível; impossível obter expat moderno" >&2
        return 1
    fi

    if ! brew list --formula expat &>/dev/null; then
        echo "  brew install expat..."
        brew install expat
    fi

    local expat_lib
    expat_lib="$(brew --prefix expat)/lib/libexpat.1.dylib"
    if [[ ! -f "$expat_lib" ]]; then
        echo "  ✗ libexpat.1.dylib não encontrado em $expat_lib" >&2
        return 1
    fi

    local lib_dynload pyexpat_so
    lib_dynload=$("$py" -c 'import sys, os; print(os.path.join(sys.prefix, "lib", f"python{sys.version_info.major}.{sys.version_info.minor}", "lib-dynload"))' 2>/dev/null)
    if [[ -z "$lib_dynload" || ! -d "$lib_dynload" ]]; then
        echo "  ✗ lib-dynload não encontrado para $py" >&2
        return 1
    fi
    pyexpat_so=$(ls "$lib_dynload"/pyexpat.cpython-*-darwin.so 2>/dev/null | head -1)
    if [[ -z "$pyexpat_so" || ! -f "$pyexpat_so" ]]; then
        echo "  ✗ pyexpat.so não encontrado em $lib_dynload" >&2
        return 1
    fi

    echo "  Patching: $pyexpat_so"
    install_name_tool -change /usr/lib/libexpat.1.dylib "$expat_lib" "$pyexpat_so"
    codesign --sign - --force "$pyexpat_so"

    if "$py" -c "import pyexpat" 2>/dev/null; then
        echo "  pyexpat OK após patch ✓"
        return 0
    fi
    echo "  ✗ pyexpat ainda partido após patch" >&2
    return 1
}

if ! fix_pyexpat_if_broken "$PYTHON"; then
    echo ""
    echo "  ⚠️  whisperx setup saltado: pyexpat de $PYTHON não funciona."
    echo "     Ver: https://github.com/Homebrew/homebrew-core/issues/277330"
    echo "     Fix definitivo: actualizar para macOS 26.3+ (Apple corrige libexpat)."
    echo "     Depois, retomar: bash $DOTFILES/setup/whisperx.sh"
    exit 0
fi

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
# transitivas. No Apple Silicon o resolver escolhe combinações OK
# (torch ≥2.4 + numpy 2.x + transformers recente). No Intel macOS o
# último wheel oficial de torch é 2.2.x — daí precisarmos de pins:
#   - numpy<2: torch 2.2 foi compilado contra NumPy 1.x (ABI break)
#   - transformers<4.45: versões mais recentes exigem torch ≥2.4 e
#     desligam-se silenciosamente quando encontram 2.2
#   - matplotlib: pyannote.audio importa-o em tasks/segmentation/
#     mixins.py mas declara-o só como extra [viz]
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    echo "  (Intel macOS detectado — pinning torch 2.2.x stack)"
    pip install --quiet \
        "torch==2.2.2" \
        "numpy<2" \
        "transformers<4.45" \
        matplotlib \
        whisperx
else
    pip install --quiet whisperx
fi

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
