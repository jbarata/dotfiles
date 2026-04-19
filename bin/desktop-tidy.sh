#!/bin/bash
# desktop-tidy.sh — Modo arrumação: mover ficheiros do Desktop para Working Info
# Disparado por skhd (ctrl+alt+cmd+w). Usa diálogos AppleScript nativos.
#
# Fluxo:
#   1. Alvos = selecção actual do Finder (se toda ela está em ~/Desktop),
#      caso contrário, todos os itens do Desktop (exceto ocultos/.DS_Store).
#   2. Para cada alvo: escolher projecto existente, criar novo, deixar na raiz,
#      saltar ou cancelar tudo.
#   3. Colisões de nome: renomear com sufixo "(2)", substituir ou saltar.
set -euo pipefail

WORKING_INFO="$HOME/Documents/Working Info"
DESKTOP="$HOME/Desktop"
mkdir -p "$WORKING_INFO"

# Sentinelas — distinguem acções de nomes de projectos na lista.
OPT_NEW="[Novo projecto...]"
OPT_ROOT="[Deixar na raiz (Working Info)]"
OPT_SKIP="[Saltar este ficheiro]"
OPT_CANCEL="[Cancelar arrumação]"
COL_RENAME="[Renomear]"
COL_REPLACE="[Substituir]"
COL_SKIP="[Saltar]"

# --- Helpers AppleScript ---------------------------------------------------
# Passam strings como `argv` para evitar escaping manual.

choose_from_list() {
  # uso: choose_from_list <prompt> <item1> <item2> ...
  local prompt="$1"
  shift
  osascript -e 'on run argv
  set thePrompt to item 1 of argv
  set theItems to items 2 thru (count of argv) of argv
  set theChoice to choose from list theItems with prompt thePrompt default items {item 1 of theItems}
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
  try
    set theResult to display dialog (item 1 of argv) default answer (item 2 of argv) buttons {"Cancelar", "OK"} default button "OK"
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
  display dialog (item 1 of argv) buttons {"OK"} default button "OK"
end run' -- "$1" >/dev/null 2>&1 || true
}

get_finder_selection() {
  osascript <<'EOF' 2>/dev/null || true
tell application "Finder"
  try
    set sel to selection
    set out to ""
    repeat with f in sel
      set out to out & (POSIX path of (f as alias)) & linefeed
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

# --- 2. Iterar e mover -----------------------------------------------------

MOVED=0
SKIPPED=0
CANCELLED=false

for src in "${TARGETS[@]}"; do
  [[ -e "$src" ]] || { SKIPPED=$((SKIPPED + 1)); continue; }
  fname="$(basename "$src")"

  # Listar projectos (subpastas top-level de Working Info), ordenados
  projects=()
  while IFS= read -r proj; do
    [[ -n "$proj" ]] && projects+=("$proj")
  done < <(find "$WORKING_INFO" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | LC_ALL=C sort)

  # Construir argumentos para choose_from_list
  items=()
  for p in "${projects[@]}"; do items+=("$p"); done
  items+=("$OPT_NEW" "$OPT_ROOT" "$OPT_SKIP" "$OPT_CANCEL")

  choice="$(choose_from_list "Arrumar: $fname" "${items[@]}")"

  case "$choice" in
    ""|"$OPT_CANCEL")
      CANCELLED=true
      break
      ;;
    "$OPT_SKIP")
      SKIPPED=$((SKIPPED + 1))
      continue
      ;;
    "$OPT_NEW")
      new_name="$(ask_text "Nome do novo projecto:" "")"
      # Sanitizar: remover slashes
      new_name="${new_name//\//_}"
      if [[ -z "$new_name" ]]; then
        SKIPPED=$((SKIPPED + 1))
        continue
      fi
      dest_dir="$WORKING_INFO/$new_name"
      mkdir -p "$dest_dir"
      ;;
    "$OPT_ROOT")
      dest_dir="$WORKING_INFO"
      ;;
    *)
      dest_dir="$WORKING_INFO/$choice"
      ;;
  esac

  dest="$dest_dir/$fname"

  # Resolver colisão
  if [[ -e "$dest" ]]; then
    col_choice="$(choose_from_list "Já existe '$fname' em $(basename "$dest_dir"). O que fazer?" "$COL_RENAME" "$COL_REPLACE" "$COL_SKIP")"
    case "$col_choice" in
      "$COL_RENAME")
        new_fname="$(next_free_name "$dest_dir" "$fname")"
        dest="$dest_dir/$new_fname"
        ;;
      "$COL_REPLACE")
        rm -rf "$dest"
        ;;
      *)
        SKIPPED=$((SKIPPED + 1))
        continue
        ;;
    esac
  fi

  if mv "$src" "$dest"; then
    MOVED=$((MOVED + 1))
  else
    SKIPPED=$((SKIPPED + 1))
  fi
done

# --- 3. Relatório final ----------------------------------------------------

if $CANCELLED; then
  info_dialog "Arrumação cancelada.\nMovidos: $MOVED\nSaltados: $SKIPPED"
else
  info_dialog "Arrumação concluída.\nMovidos: $MOVED\nSaltados: $SKIPPED"
fi
