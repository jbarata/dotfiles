#!/bin/bash
# desktop-tidy.sh — Modo arrumação: mover ficheiros do Desktop para Working Info
# Disparado por skhd (ctrl+alt+cmd+w). Usa diálogos AppleScript nativos.
#
# Fluxo:
#   1. Alvos = selecção actual do Finder (se toda ela está em ~/Desktop),
#      caso contrário, todos os itens do Desktop (exceto ocultos/.DS_Store).
#   2. Perguntar UMA VEZ o destino — aplica a mesma decisão a todos os alvos.
#   3. Colisões de nome: perguntar UMA VEZ a política — renomear com sufixo
#      "(2)", substituir ou saltar, aplicada a todos os ficheiros que colidam.
set -euo pipefail

WORKING_INFO="$HOME/Documents/Working Info"
DESKTOP="$HOME/Desktop"
mkdir -p "$WORKING_INFO"

# Sentinelas — distinguem acções de nomes de projectos na lista.
OPT_NEW="[Novo projecto...]"
OPT_ROOT="[Deixar na raiz (Working Info)]"
OPT_CANCEL="[Cancelar arrumação]"
COL_RENAME="[Renomear com sufixo (2)]"
COL_REPLACE="[Substituir]"
COL_SKIP="[Saltar os que colidem]"

# --- Helpers AppleScript ---------------------------------------------------
# Passam strings como `argv` para evitar escaping manual.

choose_from_list() {
  # uso: choose_from_list <prompt> <item1> <item2> ...
  # O diálogo é apresentado pela app frontmost para herdar o foco e garantir
  # que Enter/Esc funcionam logo, sem precisar de clicar com o rato.
  local prompt="$1"
  shift
  osascript -e 'on run argv
  set frontApp to path to frontmost application as text
  set thePrompt to item 1 of argv
  set theItems to items 2 thru (count of argv) of argv
  tell application frontApp
    set theChoice to choose from list theItems with prompt thePrompt default items {item 1 of theItems}
  end tell
  if theChoice is false then
    return ""
  else
    return item 1 of theChoice as text
  end if
end run' -- "$prompt" "$@"
}

ask_text() {
  # uso: ask_text <prompt> [default]
  local prompt="$1"
  local default="${2:-}"
  osascript -e 'on run argv
  set frontApp to path to frontmost application as text
  try
    tell application frontApp
      set theResult to display dialog (item 1 of argv) default answer (item 2 of argv) buttons {"Cancelar", "OK"} default button "OK"
    end tell
    if button returned of theResult is "OK" then
      return text returned of theResult
    else
      return ""
    end if
  on error
    return ""
  end try
end run' -- "$prompt" "$default"
}

info_dialog() {
  osascript -e 'on run argv
  set frontApp to path to frontmost application as text
  tell application frontApp
    display dialog (item 1 of argv) buttons {"OK"} default button "OK"
  end tell
end run' -- "$1" >/dev/null 2>&1 || true
}

get_finder_selection() {
  # `selection as alias list` coage a selecção inteira numa lista de aliases
  # de uma só vez — funciona uniformemente para ficheiros e pastas. A versão
  # anterior iterava referências e fazia `f as alias`, o que falhava
  # silenciosamente para directorias e caía no `on error`.
  osascript <<'EOF' 2>/dev/null || true
tell application "Finder"
  try
    set sel to selection as alias list
    set out to ""
    repeat with a in sel
      set out to out & POSIX path of a & linefeed
    end repeat
    return out
  on error
    return ""
  end try
end tell
EOF
}

# next_free_name <dir> <basename-com-ext>
# Devolve "base (2).ext" ou "base (3).ext" até encontrar nome livre.
next_free_name() {
  local dir="$1"
  local name="$2"
  local base ext candidate n=2
  if [[ "$name" == *.* && "$name" != .* ]]; then
    base="${name%.*}"
    ext=".${name##*.}"
  else
    base="$name"
    ext=""
  fi
  while true; do
    candidate="$base ($n)$ext"
    if [[ ! -e "$dir/$candidate" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
    n=$((n + 1))
  done
}

# --- 1. Determinar alvos ---------------------------------------------------

TARGETS=()
selection="$(get_finder_selection)"
use_selection=false

if [[ -n "${selection//[[:space:]]/}" ]]; then
  use_selection=true
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    path="${path%/}"
    if [[ "$path" != "$DESKTOP/"* ]]; then
      use_selection=false
      break
    fi
  done <<< "$selection"
fi

if $use_selection; then
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    TARGETS+=("${path%/}")
  done <<< "$selection"
else
  shopt -s nullglob dotglob
  for item in "$DESKTOP"/*; do
    base="$(basename "$item")"
    [[ "$base" == ".DS_Store" ]] && continue
    [[ "$base" == .* ]] && continue
    TARGETS+=("$item")
  done
  shopt -u nullglob dotglob
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  info_dialog "Desktop já está limpo — nada para arrumar."
  exit 0
fi

# --- 2. Perguntar destino UMA vez e aplicar a todos -----------------------

# Preview dos ficheiros para o prompt.
N=${#TARGETS[@]}
preview=""
max_preview=5
for ((i = 0; i < N && i < max_preview; i++)); do
  preview+=$'\n'"  • $(basename "${TARGETS[$i]}")"
done
if [[ $N -gt $max_preview ]]; then
  preview+=$'\n'"  … e mais $((N - max_preview))"
fi
prompt="Arrumar $N ficheiro(s):$preview"$'\n\n'"Destino:"

# Listar projectos (subpastas top-level), ordenados
projects=()
while IFS= read -r proj; do
  [[ -n "$proj" ]] && projects+=("$proj")
done < <(find "$WORKING_INFO" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | LC_ALL=C sort)

items=("$OPT_ROOT")
for p in "${projects[@]}"; do items+=("$p"); done
items+=("$OPT_NEW" "$OPT_CANCEL")

choice="$(choose_from_list "$prompt" "${items[@]}")"

case "$choice" in
  ""|"$OPT_CANCEL")
    info_dialog "Arrumação cancelada."
    exit 0
    ;;
  "$OPT_NEW")
    new_name="$(ask_text "Nome do novo projecto:" "")"
    new_name="${new_name//\//_}"
    if [[ -z "$new_name" ]]; then
      info_dialog "Arrumação cancelada (sem nome de projecto)."
      exit 0
    fi
    DEST_DIR="$WORKING_INFO/$new_name"
    mkdir -p "$DEST_DIR"
    ;;
  "$OPT_ROOT")
    DEST_DIR="$WORKING_INFO"
    ;;
  *)
    DEST_DIR="$WORKING_INFO/$choice"
    ;;
esac

# --- 3. Detectar colisões e perguntar política UMA vez --------------------

COLLIDE=()
for src in "${TARGETS[@]}"; do
  [[ -e "$src" ]] || continue
  fname="$(basename "$src")"
  if [[ -e "$DEST_DIR/$fname" ]]; then
    COLLIDE+=("$fname")
  fi
done

COL_POLICY=""
if [[ ${#COLLIDE[@]} -gt 0 ]]; then
  col_preview=""
  for ((i = 0; i < ${#COLLIDE[@]} && i < max_preview; i++)); do
    col_preview+=$'\n'"  • ${COLLIDE[$i]}"
  done
  if [[ ${#COLLIDE[@]} -gt $max_preview ]]; then
    col_preview+=$'\n'"  … e mais $((${#COLLIDE[@]} - max_preview))"
  fi
  col_prompt="${#COLLIDE[@]} ficheiro(s) já existem em $(basename "$DEST_DIR"):$col_preview"$'\n\n'"O que fazer?"
  COL_POLICY="$(choose_from_list "$col_prompt" "$COL_RENAME" "$COL_REPLACE" "$COL_SKIP")"
  if [[ -z "$COL_POLICY" ]]; then
    info_dialog "Arrumação cancelada."
    exit 0
  fi
fi

# --- 4. Mover ---------------------------------------------------------------

MOVED=0
SKIPPED=0
ERRORS=""

append_error() {
  # Acumula erros num relatório que é mostrado no diálogo final.
  ERRORS+=$'\n'"  • $1: $2"
}

for src in "${TARGETS[@]}"; do
  fname="$(basename "$src")"
  if [[ ! -e "$src" ]]; then
    SKIPPED=$((SKIPPED + 1))
    append_error "$fname" "origem não existe"
    continue
  fi
  dest="$DEST_DIR/$fname"

  if [[ -e "$dest" ]]; then
    case "$COL_POLICY" in
      "$COL_RENAME")
        new_fname="$(next_free_name "$DEST_DIR" "$fname")"
        dest="$DEST_DIR/$new_fname"
        ;;
      "$COL_REPLACE")
        if ! rm_err="$(rm -rf "$dest" 2>&1)"; then
          SKIPPED=$((SKIPPED + 1))
          append_error "$fname" "rm falhou: ${rm_err:-erro desconhecido}"
          continue
        fi
        ;;
      *)
        SKIPPED=$((SKIPPED + 1))
        continue
        ;;
    esac
  fi

  # Tentativa 1: mv (rename rápido no mesmo volume).
  # Pode falhar com EDEADLK/EXDEV quando ~/Desktop e ~/Documents/Working Info
  # estão em mount-points APFS/iCloud distintos (comum quando um está
  # sincronizado com iCloud Drive e o outro não). Nesse caso, fallback para
  # ditto (cópia profunda que preserva xattrs/ACLs no macOS) + rm à origem.
  if mv_err="$(mv "$src" "$dest" 2>&1)"; then
    MOVED=$((MOVED + 1))
    continue
  fi

  if ditto_err="$(ditto "$src" "$dest" 2>&1)"; then
    if rm_err="$(rm -rf "$src" 2>&1)"; then
      MOVED=$((MOVED + 1))
    else
      SKIPPED=$((SKIPPED + 1))
      append_error "$fname" "copiado mas falhou a remover origem: ${rm_err:-erro desconhecido}"
    fi
  else
    SKIPPED=$((SKIPPED + 1))
    append_error "$fname" "mv: ${mv_err:-erro}; ditto: ${ditto_err:-erro}"
  fi
done

# --- 5. Relatório final ----------------------------------------------------

report="Arrumação concluída."$'\n'"Movidos: $MOVED"$'\n'"Saltados: $SKIPPED"$'\n'"Destino: $(basename "$DEST_DIR")"
if [[ -n "$ERRORS" ]]; then
  report+=$'\n\n'"Erros:$ERRORS"
fi
info_dialog "$report"
