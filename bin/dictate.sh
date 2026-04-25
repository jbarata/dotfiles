#!/bin/bash
# dictate.sh — Toggle de ditado por voz com whisper.cpp streaming.
# Disparado por skhd (⌃⌥⌘F) ou pelo alias `dictate`.
#
# Fluxo:
#   1ª invocação ▶ arranca `whisper-stream` em background a capturar do
#     microfone default. HUD mostra "● REC" via /tmp/skhd-mode.
#   2ª invocação ⏹ envia SIGTERM ao processo, lê o output acumulado, faz
#     pbcopy + Cmd+V via osascript no app activo. Restaura o clipboard
#     anterior depois da paste.
#
# Estado:
#   /tmp/dictate.pid       — PID do whisper-stream
#   /tmp/dictate.out       — stdout do whisper-stream (texto bruto)
#   /tmp/dictate.clip.bak  — clipboard anterior (restaurado após paste)
#   /tmp/dictate.log       — log de invocações (debug)
#   /tmp/skhd-mode         — HUD do skhd-hud.widget (poll 100 ms)
#
# Pré-requisitos:
#   - whisper-stream e modelo ggml-<MODEL>.bin instalados via setup/whisper.sh
#   - Permissão de Microfone (a 1ª execução pede; aprovar em Definições →
#     Privacidade → Microfone para o "ghostty" / parent process do skhd)
#   - Permissão de Acessibilidade para o skhd (já necessária para o resto)
#
# Tunables (env):
#   WHISPER_MODEL    — default 'small' (alinhado com setup/whisper.sh)
#   WHISPER_LANG     — default 'pt' (auto-detect: 'auto')
#   WHISPER_THREADS  — default 6
set -euo pipefail

# Forçar locale UTF-8 — o skhd herda um env minimalista do launchd e LANG
# fica unset. Sem isto, `pbcopy` interpreta os bytes UTF-8 do whisper-stream
# como MacRoman ao guardá-los no clipboard, e cola "N√£o" em vez de "Não"
# em qualquer app. Os exports no shell/.exports só carregam em shells
# interactivas (.zshrc), portanto não chegam aqui.
# en_US (não pt_PT) por garantia: vem sempre instalado em macOS.
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

MODEL="${WHISPER_MODEL:-medium}"
LANG_CODE="${WHISPER_LANG:-pt}"
THREADS="${WHISPER_THREADS:-6}"

MODEL_BIN="$HOME/.local/share/whisper-models/ggml-${MODEL}.bin"
WHISPER_STREAM="$HOME/.local/bin/whisper-stream"

PID_FILE="/tmp/dictate.pid"
OUT_FILE="/tmp/dictate.out"
CLIP_BAK="/tmp/dictate.clip.bak"
LOG="/tmp/dictate.log"
HUD="/tmp/skhd-mode"

hud()  { echo "$1" > "$HUD" 2>/dev/null || true; }
log()  { echo "$(date '+%F %T') $*" >> "$LOG"; }
fail() { hud "dictate|⚠ $1"; log "FAIL: $1"; ( sleep 2; hud "" ) & exit 1; }

# --- Sanity checks (rápidos, não tornam a 2ª pressão lenta) -----------------
[[ -x "$WHISPER_STREAM" ]] || fail "whisper-stream em falta — corre setup/whisper.sh"
[[ -f "$MODEL_BIN"      ]] || fail "modelo $MODEL em falta — corre setup/whisper.sh"

# --- Toggle: se já há um stream a correr, pára e cola ----------------------
if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    PID=$(cat "$PID_FILE")
    log "STOP pid=$PID"
    hud "dictate|⏹ a transcrever…"

    # SIGTERM dá tempo ao whisper-stream para fazer flush do último segmento.
    kill -TERM "$PID" 2>/dev/null || true
    # Espera até 3s pelo término (não bloqueia indefinidamente).
    for _ in 1 2 3 4 5 6; do
        kill -0 "$PID" 2>/dev/null || break
        sleep 0.5
    done
    kill -KILL "$PID" 2>/dev/null || true
    rm -f "$PID_FILE"

    # whisper-stream emite linhas como "[Start --> End]   texto" e linhas
    # vazias / "### Transcription N START/END". Filtramos só o texto útil.
    if [[ ! -s "$OUT_FILE" ]]; then
        hud "dictate|∅ sem áudio"
        ( sleep 1.5; hud "" ) &
        log "STOP: output vazio"
        exit 0
    fi

    TEXT=$(
        sed -E '/^###/d; /^$/d; s/^\[[^]]*\][[:space:]]*//' "$OUT_FILE" \
            | tr '\n' ' ' \
            | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
    )

    if [[ -z "$TEXT" ]]; then
        hud "dictate|∅ sem texto"
        ( sleep 1.5; hud "" ) &
        log "STOP: texto vazio após filtro"
        exit 0
    fi

    log "STOP: text='$TEXT'"

    # Save → set → paste → restore clipboard. pbpaste pode falhar se o
    # clipboard estiver vazio ou com conteúdo não-texto; nesse caso
    # apenas saltamos o restore.
    pbpaste > "$CLIP_BAK" 2>/dev/null || : > "$CLIP_BAK"
    printf '%s' "$TEXT" | pbcopy
    osascript -e 'tell application "System Events" to keystroke "v" using command down' 2>/dev/null || true
    # Pequeno delay para a paste consumir o clipboard antes de o restaurarmos.
    ( sleep 0.4; pbcopy < "$CLIP_BAK"; rm -f "$CLIP_BAK" ) &

    hud "dictate|✓ colado"
    ( sleep 1.2; hud "" ) &
    rm -f "$OUT_FILE"
    exit 0
fi

# --- Arranque: limpa estado antigo e lança whisper-stream em background ----
rm -f "$OUT_FILE" "$PID_FILE"
log "START model=$MODEL lang=$LANG_CODE"

# Flags do whisper-stream:
#   --step 0          — modo "VAD" (só processa em silêncio, sem partial duplo)
#   --length 5000     — janela máxima por chunk (ms)
#   --keep 200        — overlap (ms) entre chunks para evitar cortes a meio
#   -t $THREADS       — threads de inferência
#   -l $LANG_CODE     — língua (pt aqui; 'auto' deixa whisper detectar)
#   -m <bin>          — modelo ggml; o .mlmodelc encoder é carregado
#                       automaticamente se existir ao lado.
nohup "$WHISPER_STREAM" \
    -m "$MODEL_BIN" \
    -t "$THREADS" \
    -l "$LANG_CODE" \
    --step 0 \
    --length 5000 \
    --keep 200 \
    > "$OUT_FILE" 2>>"$LOG" &

echo $! > "$PID_FILE"
hud "dictate|● REC ($MODEL/$LANG_CODE) — ⌃⌥⌘F para parar"
log "START pid=$(cat "$PID_FILE")"

# Health-check: se o whisper-stream morrer logo no init (modelo corrupto,
# Core ML partido, permissão de microfone negada) o PID fica órfão e a
# próxima pressão re-arranca outro condenado. Damos 0.8s para a janela
# típica de erro de inicialização e abortamos com feedback claro.
sleep 0.8
if ! kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
    rm -f "$PID_FILE"
    hud "dictate|⚠ whisper-stream falhou — ver /tmp/dictate.log"
    ( sleep 3; hud "" ) &
    log "START: processo morreu no init (ver linhas acima)"
    exit 1
fi
