#!/bin/bash
# setup/whisper.sh — Build whisper.cpp + modelo + (Apple Silicon) Core ML
#
# Padrão alinhado com setup/cob-tools.sh: clona em ~/.local/src/, compila,
# instala binários em ~/.local/bin/ (já no PATH via .zshrc). Idempotente.
#
# Estrutura final:
#   ~/.local/src/whisper.cpp/                 — repo + build/
#   ~/.local/bin/whisper-cli                  — symlink → build/bin/whisper-cli
#   ~/.local/bin/whisper-stream               — symlink → build/bin/whisper-stream
#   ~/.local/share/whisper-models/ggml-<m>.bin
#   ~/.local/share/whisper-models/ggml-<m>-encoder.mlmodelc/   (só Apple Silicon)
#   ~/.local/share/whisper-coreml-venv/       — venv isolado para conversão Core ML
#
# Variáveis (override via env):
#   WHISPER_MODEL    default: small (multilingue, PT+EN)
#   WHISPER_COREML   default: 1 em arm64, 0 em x86_64
set -euo pipefail

SRC_DIR="$HOME/.local/src"
WHISPER_DIR="$SRC_DIR/whisper.cpp"
WHISPER_REPO="https://github.com/ggml-org/whisper.cpp.git"
BIN_DIR="$HOME/.local/bin"
MODELS_DIR="$HOME/.local/share/whisper-models"
COREML_VENV="$HOME/.local/share/whisper-coreml-venv"

WHISPER_MODEL="${WHISPER_MODEL:-small}"
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    WHISPER_COREML="${WHISPER_COREML:-1}"
else
    WHISPER_COREML="${WHISPER_COREML:-0}"
fi

mkdir -p "$SRC_DIR" "$BIN_DIR" "$MODELS_DIR"

# --- 1. Clone / pull -----------------------------------------------------
if [[ -d "$WHISPER_DIR/.git" ]]; then
    echo "  A actualizar $WHISPER_DIR..."
    git -C "$WHISPER_DIR" pull --quiet --ff-only || {
        echo "  AVISO: git pull falhou (working tree sujo?). A continuar com o estado actual."
    }
else
    echo "  A clonar $WHISPER_REPO → $WHISPER_DIR..."
    git clone --quiet "$WHISPER_REPO" "$WHISPER_DIR"
fi

# --- 2. Build com cmake (SDL2 ON para o stream; Core ML em arm64) --------
CMAKE_FLAGS=(-DWHISPER_SDL2=ON -DCMAKE_BUILD_TYPE=Release)
if [[ "$WHISPER_COREML" == "1" ]]; then
    # ALLOW_FALLBACK: sem este flag, falhar a carregar .mlmodelc aborta o
    # whisper context inteiro (mesmo com Metal disponível). Com ele, perde
    # apenas a aceleração Core ML e segue em Metal — diferença ~3× no
    # encoder em modelos small/medium, irrelevante para uso interactivo.
    # Indispensável quando o .mlmodelc gerado pelo coremltools acaba
    # incompatível (versões coremlc/Sequoia) ou parcial.
    CMAKE_FLAGS+=(-DWHISPER_COREML=1 -DWHISPER_COREML_ALLOW_FALLBACK=1)
    echo "  Build: SDL2 + Core ML (arm64, fallback p/ Metal se .mlmodelc falhar)"
else
    echo "  Build: SDL2 (x86_64 — Core ML não disponível)"
fi

(
    cd "$WHISPER_DIR"
    cmake -B build "${CMAKE_FLAGS[@]}" >/dev/null
    cmake --build build -j --config Release
)

# --- 3. Symlinks dos binários em ~/.local/bin ----------------------------
for bin in whisper-cli whisper-stream; do
    src="$WHISPER_DIR/build/bin/$bin"
    dst="$BIN_DIR/$bin"
    if [[ ! -x "$src" ]]; then
        echo "  AVISO: $bin não foi compilado (esperado em $src). A saltar symlink."
        continue
    fi
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        continue
    fi
    [[ -e "$dst" || -L "$dst" ]] && rm "$dst"
    ln -s "$src" "$dst"
    echo "  Link: $dst → $src"
done

# --- 4. Download do(s) modelo(s) ggml -----------------------------------
# Tamanho mínimo esperado (em MB) para detectar downloads truncados. Os
# números reais são ~10% maiores; usamos 90% como threshold seguro. O
# `download-ggml-model.sh` upstream verifica só presença ("skip if exists"),
# o que mantém ficheiros parciais de Ctrl+C/falhas de rede e propaga o
# problema sem aviso até o whisper-cli explodir com "expected N, got M".
expected_size_mb() {
    case "$1" in
        tiny|tiny.en)               echo 70 ;;
        base|base.en)               echo 140 ;;
        small|small.en)             echo 460 ;;
        medium|medium.en)           echo 1500 ;;
        large-v1|large-v2|large-v3) echo 3000 ;;
        *)                          echo 0 ;;
    esac
}

# Helper: descarrega um modelo se ainda não existir em $MODELS_DIR.
# Se já existir mas estiver truncado, apaga e re-descarrega.
download_model() {
    local model="$1"
    local target="$MODELS_DIR/ggml-${model}.bin"
    local source="$WHISPER_DIR/models/ggml-${model}.bin"
    local min_mb size_mb
    min_mb=$(expected_size_mb "$model")

    # Valida o target existente — pode estar truncado de uma run anterior.
    if [[ -f "$target" ]]; then
        size_mb=$(( $(stat -f%z "$target") / 1048576 ))
        if [[ "$min_mb" -gt 0 && "$size_mb" -lt "$min_mb" ]]; then
            echo "  AVISO: modelo $model truncado ($size_mb MB < esperado ~$min_mb MB) — a re-descarregar"
            rm -f "$target"
        else
            echo "  Modelo $model já presente: $target ($size_mb MB)"
            return 0
        fi
    fi

    # Garante que o source também não tem lixo de uma run interrompida —
    # caso contrário o upstream diz "already exists" e perpetua o problema.
    if [[ -f "$source" ]]; then
        size_mb=$(( $(stat -f%z "$source") / 1048576 ))
        if [[ "$min_mb" -gt 0 && "$size_mb" -lt "$min_mb" ]]; then
            echo "  AVISO: source $source truncado ($size_mb MB) — a apagar antes do download"
            rm -f "$source"
        fi
    fi

    echo "  A descarregar modelo ggml-${model}..."
    # O script do upstream descarrega para ./models/ no cwd; corremos lá e
    # movemos para o local centralizado depois de validar o tamanho.
    (cd "$WHISPER_DIR" && bash models/download-ggml-model.sh "$model")

    if [[ ! -f "$source" ]]; then
        echo "  ERRO: download de $model não produziu ficheiro em $source" >&2
        return 1
    fi

    size_mb=$(( $(stat -f%z "$source") / 1048576 ))
    if [[ "$min_mb" -gt 0 && "$size_mb" -lt "$min_mb" ]]; then
        echo "  ERRO: modelo $model descarregado truncado ($size_mb MB < ~$min_mb MB)" >&2
        echo "        Apaguei o ficheiro parcial. Verifica a rede e corre de novo:" >&2
        echo "          bash $DOTFILES/setup/whisper.sh" >&2
        rm -f "$source"
        return 1
    fi

    mv "$source" "$target"
    echo "  Modelo $model: $target ($size_mb MB)"
}

# Modelo primário (streaming via dictate.sh) — pequeno, tempo-real
download_model "$WHISPER_MODEL"
MODEL_BIN="$MODELS_DIR/ggml-${WHISPER_MODEL}.bin"

# Modelo offline (batch via transcribe.sh) — grande, qualidade alta. Só
# descarrega se for diferente do primário; user pode forçar via env.
WHISPER_OFFLINE_MODEL="${WHISPER_OFFLINE_MODEL:-large-v3}"
if [[ "$WHISPER_OFFLINE_MODEL" != "$WHISPER_MODEL" ]]; then
    download_model "$WHISPER_OFFLINE_MODEL"
fi

# --- 5. Core ML encoder (só arm64) --------------------------------------
# Acelera o encoder ~3× em modelos small/medium. Geração precisa de
# Python 3.11 + torch + coremltools + ane_transformers + openai-whisper.
#
# Pin de Python 3.11: ane_transformers prende torch 2.x; torch e coremltools
# não têm wheels para cp313/cp314. O Python do sistema (3.14 em macOS Sequoia
# recente) parte na criação do venv ou no `pip install torch`. Brew formula
# `python@3.11` instala /opt/homebrew/bin/python3.11 sem mexer no `python3`
# do sistema.
#
# Best effort: se algo falhar, avisamos e seguimos. whisper-stream funciona
# em Metal puro à mesma — só perde ~3× no encoder em modelos grandes.
generate_coreml_model() {
    local mlmodelc_dir="$MODELS_DIR/ggml-${WHISPER_MODEL}-encoder.mlmodelc"

    if [[ -d "$mlmodelc_dir" ]]; then
        echo "  Core ML encoder já gerado: $mlmodelc_dir"
        return 0
    fi

    # Python 3.11 é o sweet spot. 3.12 funciona com coremltools recente mas
    # ane_transformers ainda não publicou wheels limpas para 3.12; ficamos
    # no 3.11 que cobre os dois caminhos.
    local coreml_python=""
    for candidate in python3.11 python3.12; do
        if command -v "$candidate" >/dev/null 2>&1; then
            coreml_python="$candidate"
            break
        fi
    done

    if [[ -z "$coreml_python" ]]; then
        echo "  AVISO: nenhum Python 3.11/3.12 encontrado."
        echo "         Instala com: brew install python@3.11"
        echo "         Depois corre de novo: bash $DOTFILES/setup/whisper.sh"
        echo "         (whisper-stream funciona em Metal puro entretanto)"
        return 0
    fi

    # Pre-flight: `coremlc` é o compilador Apple que converte .mlpackage →
    # .mlmodelc. Vive dentro do bundle do Xcode completo
    # (Xcode.app/Contents/Developer/...), não das Command Line Tools. Sem
    # Xcode, mesmo que toda a conversão PyTorch → MIL passe (e demora ~5 min
    # + 2 GB de venv com torch+coremltools), o último passo `xcrun coremlc
    # compile` falha. Evitamos toda essa volta verificando à cabeça.
    if ! xcrun --find coremlc >/dev/null 2>&1; then
        echo "  AVISO: coremlc não encontrado — Core ML requer Xcode completo (CLT não basta)."
        echo "         Para activar Core ML mais tarde:"
        echo "           1. Instalar Xcode da App Store (~12 GB)"
        echo "           2. sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
        echo "           3. bash $DOTFILES/setup/whisper.sh  (retoma só a parte Core ML)"
        echo "         Build com WHISPER_COREML_ALLOW_FALLBACK=1: whisper-stream"
        echo "         corre em Metal puro à mesma — \`small\` no M2 já é tempo real."
        return 0
    fi

    echo "  A gerar Core ML encoder para $WHISPER_MODEL com $coreml_python (5–10 min, ~2 GB no venv)..."

    # Se houver um venv pré-existente criado com outra versão (ex.: tentativa
    # falhada com python3.14 no macOS Sequoia), apaga e recria. Detectamos
    # pela ausência do binário esperado em $COREML_VENV/bin/.
    if [[ -d "$COREML_VENV" && ! -x "$COREML_VENV/bin/$coreml_python" ]]; then
        echo "  Venv existente foi criado com outro Python — a recriar..."
        rm -rf "$COREML_VENV"
    fi

    if [[ ! -d "$COREML_VENV" ]]; then
        if ! "$coreml_python" -m venv "$COREML_VENV"; then
            echo "  AVISO: falha a criar venv com $coreml_python — a saltar Core ML."
            rm -rf "$COREML_VENV"
            return 0
        fi
    fi

    # shellcheck disable=SC1091
    source "$COREML_VENV/bin/activate"

    # `set -e` só corta na shell actual; aqui controlamos manualmente para
    # poder fazer `deactivate` antes de retornar em caso de erro.
    if ! pip install --quiet --upgrade pip; then
        echo "  AVISO: pip upgrade falhou — a saltar Core ML."
        deactivate
        return 0
    fi

    if ! pip install --quiet ane_transformers openai-whisper coremltools; then
        echo "  AVISO: pip install (ane_transformers/openai-whisper/coremltools) falhou."
        echo "         O whisper-stream segue com Metal puro."
        deactivate
        return 0
    fi

    # O script upstream gera ./models/coreml-encoder-<model>.mlpackage
    # e compila para .mlmodelc no mesmo path.
    if ! ( cd "$WHISPER_DIR" && bash ./models/generate-coreml-model.sh "$WHISPER_MODEL" ); then
        echo "  AVISO: generate-coreml-model.sh falhou."
        deactivate
        return 0
    fi

    deactivate

    local generated="$WHISPER_DIR/models/ggml-${WHISPER_MODEL}-encoder.mlmodelc"
    if [[ -d "$generated" ]]; then
        mv "$generated" "$mlmodelc_dir"
        echo "  Core ML encoder: $mlmodelc_dir"
    else
        echo "  AVISO: .mlmodelc não foi gerado em $generated."
        echo "         O whisper-stream segue com Metal puro."
    fi
}

if [[ "$WHISPER_COREML" == "1" ]]; then
    generate_coreml_model
fi

echo ""
echo "  Whisper pronto."
echo "    Modelo:   $MODEL_BIN"
echo "    Binários: $BIN_DIR/whisper-cli, $BIN_DIR/whisper-stream"
echo "    Trigger:  Ctrl+Alt+Cmd+F  (toggle dictate)  ou  alias 'dictate'"
