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
