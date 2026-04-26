#!/bin/bash
# transcribe-diarize.sh — Como `transcribe`, mas com identificação de
# oradores via whisperx (faster-whisper + pyannote.audio). Output SRT/TXT
# com `[SPEAKER_00]`, `[SPEAKER_01]`, ... por segmento.
#
# Uso:
#   transcribe-diarize <ficheiro-audio> [...]
#
# Output:
#   ~/Desktop/<basename>.srt
#   ~/Desktop/<basename>.txt
#
# Pré-requisitos:
#   - bash setup/whisperx.sh    (cria venv + instala whisperx)
#   - HuggingFace token em op://<vault>/HuggingFace/token
#     (default: op://Private/HuggingFace/token, override via env)
#   - Aceitar T&C dos modelos pyannote (ver setup/whisperx.sh)
#
# Tunables (env):
#   WHISPER_OFFLINE_MODEL       default: large-v3
#   WHISPER_LANG                default: pt (`auto` para detectar)
#   WHISPERX_HF_TOKEN_OP_REF    default: op://Private/HuggingFace/token
#   WHISPER_OUT_DIR             default: ~/Desktop
#   WHISPERX_MIN_SPEAKERS       opcional, hint para o pyannote
#   WHISPERX_MAX_SPEAKERS       opcional, hint para o pyannote
#   WHISPERX_COMPUTE_TYPE       default: int8 (~2× face a float32 em CPU,
#                               quality drop imperceptível em PT). Outras:
#                               int8_float16, float16, float32
#   HF_HUB_OFFLINE              opcional (=1): força modo offline (falha
#                               imediatamente se faltar algum modelo na
#                               cache). Útil para áudios sensíveis depois
#                               do 1º download.
set -euo pipefail

# Forçar locale UTF-8 (mesma razão que dictate.sh / transcribe.sh: env
# herdado pelo shell pode não ter LANG; pyannote e os outputs em PT
# usam acentos).
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Defesa em profundidade: huggingface_hub envia telemetria anónima por
# defeito (versão da lib + nome do modelo carregado, nunca o input áudio).
# Desligar é gratuito.
export HF_HUB_DISABLE_TELEMETRY=1

# Suprimir UserWarnings — pyannote.audio importa torchcodec que falha a
# carregar dylibs do ffmpeg do brew (rpath mismatch); cai em soundfile e
# funciona, mas o warning aparece a cada invocação. Outros UserWarnings
# do PyTorch/torchaudio também tendem a poluir output útil. Override
# por sessão se precisares de ver: PYTHONWARNINGS=default transcribe-diarize.
export PYTHONWARNINGS="${PYTHONWARNINGS:-ignore::UserWarning}"

# Em macOS Intel (x86_64), torch 2.2 + MKL + libomp dão deadlock no
# teardown do processo: a transcrição completa, o output é escrito, mas
# o processo Python fica em estado `sleeping` (CPU 0%, ctrl+c ignorado)
# porque a libiomp5 do MKL e a libomp do torch não conseguem sincronizar
# o shutdown dos thread pools. Workaround: forçar uma única OpenMP
# runtime (KMP_DUPLICATE_LIB_OK) e evitar threading agressivo. Custo:
# inferência single-thread (~real-time em tiny/base, várias×real-time
# em large-v3). Apple Silicon não tem este problema — não setamos lá.
WHISPERX_EXTRA_FLAGS=()
if [[ "$(uname -m)" == "x86_64" ]]; then
    export OMP_NUM_THREADS=1
    export MKL_NUM_THREADS=1
    export KMP_DUPLICATE_LIB_OK=TRUE
    WHISPERX_EXTRA_FLAGS+=(--threads 1)
fi

MODEL="${WHISPER_OFFLINE_MODEL:-large-v3}"
LANG_CODE="${WHISPER_LANG:-pt}"
COMPUTE_TYPE="${WHISPERX_COMPUTE_TYPE:-int8}"
OUT_DIR="${WHISPER_OUT_DIR:-$HOME/Desktop}"
HF_TOKEN_REF="${WHISPERX_HF_TOKEN_OP_REF:-op://Private/HuggingFace/token}"

WHISPERX_VENV="$HOME/.local/share/whisperx-venv"
WHISPERX_BIN="$WHISPERX_VENV/bin/whisperx"

# --- Sanity checks ---------------------------------------------------------
[[ -x "$WHISPERX_BIN" ]] || {
    echo "✗ whisperx em falta — corre: bash ~/.dotfiles/setup/whisperx.sh" >&2
    exit 1
}
command -v ffmpeg >/dev/null || {
    echo "✗ ffmpeg em falta — brew install ffmpeg" >&2
    exit 1
}
command -v op >/dev/null || {
    echo "✗ 1Password CLI 'op' em falta — brew install 1password-cli" >&2
    exit 1
}

if [[ $# -eq 0 ]]; then
    echo "Uso: transcribe-diarize <ficheiro-audio> [...]" >&2
    echo "" >&2
    echo "Para o Dictafone do macOS: arrasta a gravação para esta janela" >&2
    echo "(o Ghostty cola o path .qta) e prime Enter." >&2
    exit 1
fi

# --- Carregar HF token via 1Password ---------------------------------------
# `op read` é lazy — só corre uma vez por invocação. Se o desktop 1Password
# está unlocked + biometric integration on, é instantâneo.
if ! HF_TOKEN=$(op read "$HF_TOKEN_REF" 2>/dev/null); then
    echo "✗ Falha a ler HF token de $HF_TOKEN_REF" >&2
    echo "" >&2
    echo "  Setup manual:" >&2
    echo "    1. huggingface.co → criar conta + Access Token (read scope)" >&2
    echo "    2. Aceitar T&C em:" >&2
    echo "         https://huggingface.co/pyannote/speaker-diarization-community-1" >&2
    echo "         https://huggingface.co/pyannote/segmentation-3.0" >&2
    echo "    3. 1Password → vault Private → item 'HuggingFace' → campo 'token'" >&2
    echo "" >&2
    echo "  Override: WHISPERX_HF_TOKEN_OP_REF=op://<vault>/<item>/<field>" >&2
    exit 1
fi

if [[ -z "$HF_TOKEN" ]]; then
    echo "✗ Token vazio em $HF_TOKEN_REF" >&2
    exit 1
fi

mkdir -p "$OUT_DIR"

# --- Flags opcionais para hint do pyannote ---------------------------------
SPEAKER_FLAGS=()
[[ -n "${WHISPERX_MIN_SPEAKERS:-}" ]] && SPEAKER_FLAGS+=(--min_speakers "$WHISPERX_MIN_SPEAKERS")
[[ -n "${WHISPERX_MAX_SPEAKERS:-}" ]] && SPEAKER_FLAGS+=(--max_speakers "$WHISPERX_MAX_SPEAKERS")

# --- Loop de transcrição + diarização --------------------------------------
for INPUT in "$@"; do
    if [[ ! -f "$INPUT" ]]; then
        echo "  ✗ ficheiro não existe: $INPUT" >&2
        continue
    fi

    BASE=$(basename "${INPUT%.*}")
    OUT_PREFIX="$OUT_DIR/$BASE"

    echo "→ $INPUT"
    echo "  whisperx ($MODEL/$LANG_CODE/$COMPUTE_TYPE) + diarização pyannote → $OUT_DIR/"
    echo "  (1ª invocação descarrega modelos: large-v3 CT2 ~3 GB + pyannote ~500 MB)"

    # whisperx aceita o input directamente (sem passar pelo nosso ffmpeg
    # — chama-o internamente). Output é escrito no --output_dir com o
    # mesmo basename do input.
    # whisperx CLI aceita apenas UM valor em --output_format (último ganha
    # se passares múltiplos). `all` gera todos: txt, srt, vtt, json, tsv,
    # aud. Apagamos os que não queremos a seguir para manter consistência
    # com transcribe.sh (só txt + srt em ~/Desktop).
    #
    # Nota: ${SPEAKER_FLAGS[@]+"${SPEAKER_FLAGS[@]}"} é o idiomático
    # bash 3.2-safe para expandir um array potencialmente vazio sob
    # `set -u`. Em bash ≥4.4 bastaria "${SPEAKER_FLAGS[@]}", mas o
    # /bin/bash do macOS é 3.2 e trata array vazio como unbound.
    "$WHISPERX_BIN" \
        "$INPUT" \
        --model "$MODEL" \
        --language "$LANG_CODE" \
        --compute_type "$COMPUTE_TYPE" \
        --diarize \
        --hf_token "$HF_TOKEN" \
        --output_dir "$OUT_DIR" \
        --output_format all \
        ${WHISPERX_EXTRA_FLAGS[@]+"${WHISPERX_EXTRA_FLAGS[@]}"} \
        ${SPEAKER_FLAGS[@]+"${SPEAKER_FLAGS[@]}"}

    # Limpeza dos formatos extra (vtt/json/tsv/aud).
    for ext in vtt json tsv aud; do
        rm -f "$OUT_PREFIX.$ext"
    done

    # Post-flight: verificar que os outputs realmente existem.
    if [[ ! -f "$OUT_PREFIX.txt" || ! -f "$OUT_PREFIX.srt" ]]; then
        echo "  ✗ outputs não criados em $OUT_DIR/" >&2
        echo "    Ficheiros presentes para este input:" >&2
        ls -1 "$OUT_PREFIX".* 2>/dev/null | sed 's/^/      /' >&2 || echo "      (nenhum)" >&2
        echo "    Causas possíveis:" >&2
        echo "      - T&C de pyannote/speaker-diarization-community-1 ou pyannote/segmentation-3.0 não aceites" >&2
        echo "      - HF token sem scope 'read'" >&2
        echo "      - Modelo CT2 ainda a descarregar e ligação caiu" >&2
        echo "      - whisperx mudou flags de output entre versões" >&2
        exit 1
    fi
    echo "  ✓ $OUT_PREFIX.txt"
    echo "  ✓ $OUT_PREFIX.srt"
done
