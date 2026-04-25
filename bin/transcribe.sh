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
#   WHISPER_OUT_DIR        default: directório do input se for gravável,
#                          senão ~/Desktop. Override fixa o destino para
#                          todos os outputs (ex.: ~/Documents/Transcriptions)
set -euo pipefail

MODEL="${WHISPER_OFFLINE_MODEL:-large-v3}"
LANG_CODE="${WHISPER_LANG:-auto}"
THREADS="${WHISPER_THREADS:-8}"
OUT_DIR_OVERRIDE="${WHISPER_OUT_DIR:-}"

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

    BASE=$(basename "${INPUT%.*}")

    # Decidir directório de output:
    #   1. WHISPER_OUT_DIR explícito (sem questões)
    #   2. dirname do input se for gravável (caso típico: ~/Downloads/)
    #   3. ~/Desktop como fallback (caso típico: ficheiros sandboxed do
    #      Dictafone macOS, em ~/Library/Containers/.../tmp/, que são
    #      legíveis mas não graváveis pelo shell por TCC).
    if [[ -n "$OUT_DIR_OVERRIDE" ]]; then
        OUT_DIR="$OUT_DIR_OVERRIDE"
        mkdir -p "$OUT_DIR"
    else
        OUT_DIR=$(dirname "$INPUT")
        WRITETEST="$OUT_DIR/.transcribe-writetest-$$"
        if touch "$WRITETEST" 2>/dev/null; then
            rm -f "$WRITETEST"
        else
            OUT_DIR="$HOME/Desktop"
            echo "  ⓘ $(dirname "$INPUT") não é gravável (sandbox?); output → $OUT_DIR/" >&2
        fi
    fi

    OUT_PREFIX="$OUT_DIR/$BASE"
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

    # whisper-cli pode falhar a escrever silenciosamente (open() EACCES no
    # sandbox container) e ainda devolver 0. Verificar à mão é a única
    # garantia.
    if [[ ! -f "$OUT_PREFIX.txt" || ! -f "$OUT_PREFIX.srt" ]]; then
        echo "  ✗ outputs não criados em $OUT_DIR/" >&2
        echo "    (whisper-cli pode ter falhado o open(); ver mensagens acima)" >&2
        echo "    Tenta fixar o destino: WHISPER_OUT_DIR=~/Desktop transcribe \"$INPUT\"" >&2
        exit 1
    fi
    echo "  ✓ $OUT_PREFIX.txt"
    echo "  ✓ $OUT_PREFIX.srt"
done
