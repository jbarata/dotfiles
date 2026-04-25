#!/bin/bash
# transcribe.sh — Transcreve ficheiros áudio (m4a do iPhone, qta do
# Dictafone, mp3, wav, mp4…) usando whisper.cpp offline com modelo grande
# (qualidade > velocidade). Output: <ficheiro>.txt + <ficheiro>.srt ao
# lado do original.
#
# Uso:
#   transcribe <ficheiro-audio> [...]
#
# Para o Dictafone do macOS (que guarda em CloudKit opaco), arrasta a
# gravação para o Ghostty — o terminal cola o path do ficheiro `.qta`
# materializado temporariamente — e Enter.
#
# Pré-requisitos:
#   - bash setup/whisper.sh (descarrega large-v3 + binários)
#   - brew install ffmpeg (resample 16 kHz mono PCM, formato exigido pelo
#     whisper.cpp)
#
# Tunables (env):
#   WHISPER_OFFLINE_MODEL  default: large-v3
#   WHISPER_LANG           default: auto (deixa whisper detectar; útil
#                          para gravações multi-língua)
#   WHISPER_THREADS        default: 8 (M2 Max tem 8 cores P; CPU fallback
#                          quando Metal/Core ML não dão conta)
set -euo pipefail

MODEL="${WHISPER_OFFLINE_MODEL:-large-v3}"
LANG_CODE="${WHISPER_LANG:-auto}"
THREADS="${WHISPER_THREADS:-8}"

MODEL_BIN="$HOME/.local/share/whisper-models/ggml-${MODEL}.bin"
WHISPER_CLI="$HOME/.local/bin/whisper-cli"

# --- Sanity checks ---------------------------------------------------------
[[ -x "$WHISPER_CLI" ]] || { echo "✗ whisper-cli em falta — corre setup/whisper.sh" >&2; exit 1; }
[[ -f "$MODEL_BIN"   ]] || { echo "✗ modelo $MODEL em falta — corre setup/whisper.sh" >&2; exit 1; }
command -v ffmpeg >/dev/null || { echo "✗ ffmpeg em falta — brew install ffmpeg" >&2; exit 1; }

if [[ $# -eq 0 ]]; then
    echo "Uso: transcribe <ficheiro-audio> [...]" >&2
    echo "" >&2
    echo "Para o Dictafone do macOS: arrasta a gravação para esta janela" >&2
    echo "(o Ghostty cola o path .qta) e prime Enter." >&2
    exit 1
fi

# --- Loop de transcrição ---------------------------------------------------
for INPUT in "$@"; do
    if [[ ! -f "$INPUT" ]]; then
        echo "  ✗ ficheiro não existe: $INPUT" >&2
        continue
    fi

    OUT_PREFIX="${INPUT%.*}"
    TMP_WAV=$(mktemp -t transcribe).wav

    echo "→ $INPUT"
    echo "  [1/2] ffmpeg → 16 kHz mono PCM"
    # -ar 16000: sample rate exigido pelo whisper
    # -ac 1:     mono
    # -c:a pcm_s16le: WAV PCM 16-bit little-endian
    # -loglevel error: sem ruído de progresso (whisper-cli faz o seu)
    ffmpeg -loglevel error -y -i "$INPUT" -ar 16000 -ac 1 -c:a pcm_s16le "$TMP_WAV"

    echo "  [2/2] whisper-cli ($MODEL/$LANG_CODE)"
    # -of <prefix>: output prefix (whisper anexa .txt/.srt automaticamente)
    # -pp:          print progress (útil para ficheiros longos)
    "$WHISPER_CLI" \
        -m "$MODEL_BIN" \
        -t "$THREADS" \
        -l "$LANG_CODE" \
        -otxt -osrt \
        -of "$OUT_PREFIX" \
        -pp \
        -f "$TMP_WAV"

    rm -f "$TMP_WAV"
    echo "  ✓ $OUT_PREFIX.txt"
    echo "  ✓ $OUT_PREFIX.srt"
done
