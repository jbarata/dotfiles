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
    CMAKE_FLAGS+=(-DWHISPER_COREML=1)
    echo "  Build: SDL2 + Core ML (arm64)"
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

# --- 4. Download do modelo ggml -----------------------------------------
MODEL_BIN="$MODELS_DIR/ggml-${WHISPER_MODEL}.bin"
if [[ -f "$MODEL_BIN" ]]; then
    echo "  Modelo $WHISPER_MODEL já presente: $MODEL_BIN"
else
    echo "  A descarregar modelo ggml-${WHISPER_MODEL}..."
    # O script do upstream descarrega para ./models/ no cwd; corremos lá e
    # movemos para o local centralizado.
    (cd "$WHISPER_DIR" && bash models/download-ggml-model.sh "$WHISPER_MODEL")
    mv "$WHISPER_DIR/models/ggml-${WHISPER_MODEL}.bin" "$MODEL_BIN"
fi

# --- 5. Core ML encoder (só arm64) --------------------------------------
# Acelera o encoder ~3× em modelos small/medium. Geração precisa de
# Python + torch + coremltools + ane_transformers + openai-whisper.
# Mantemos tudo num venv isolado para não tocar no Python do sistema.
if [[ "$WHISPER_COREML" == "1" ]]; then
    MLMODELC_DIR="$MODELS_DIR/ggml-${WHISPER_MODEL}-encoder.mlmodelc"
    if [[ -d "$MLMODELC_DIR" ]]; then
        echo "  Core ML encoder já gerado: $MLMODELC_DIR"
    else
        echo "  A gerar Core ML encoder para $WHISPER_MODEL (5–10 min, ~2 GB de deps no venv)..."

        if [[ ! -d "$COREML_VENV" ]]; then
            python3 -m venv "$COREML_VENV"
        fi
        # shellcheck disable=SC1091
        source "$COREML_VENV/bin/activate"
        pip install --quiet --upgrade pip
        # ane_transformers fixa torch==2.1.0; openai-whisper e coremltools
        # são compatíveis com essa versão.
        pip install --quiet ane_transformers openai-whisper coremltools

        # O script upstream gera ./models/coreml-encoder-<model>.mlpackage
        # e compila para .mlmodelc no mesmo path.
        (
            cd "$WHISPER_DIR"
            bash ./models/generate-coreml-model.sh "$WHISPER_MODEL"
        )
        deactivate

        GENERATED_MLMODELC="$WHISPER_DIR/models/ggml-${WHISPER_MODEL}-encoder.mlmodelc"
        if [[ -d "$GENERATED_MLMODELC" ]]; then
            mv "$GENERATED_MLMODELC" "$MLMODELC_DIR"
            echo "  Core ML encoder: $MLMODELC_DIR"
        else
            echo "  AVISO: .mlmodelc não foi gerado em $GENERATED_MLMODELC."
            echo "         O whisper-stream segue com Metal puro (sem Core ML)."
        fi
    fi
fi

echo ""
echo "  Whisper pronto."
echo "    Modelo:   $MODEL_BIN"
echo "    Binários: $BIN_DIR/whisper-cli, $BIN_DIR/whisper-stream"
echo "    Trigger:  Ctrl+Alt+Cmd+F  (toggle dictate)  ou  alias 'dictate'"
