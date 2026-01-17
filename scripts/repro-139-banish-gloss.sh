#!/bin/sh
# Minimal reproduction for banish gloss SIGSEGV (exit 139).
# This script synthesizes a banish() gloss wrapper if it is not present.

show_usage() {
  cat <<'USAGE'
Usage: repro-139-banish-gloss.sh

Runs a minimal reproduction of the banish gloss crash.
Set BANISH_REPRO_XTRACE=1 to enable xtrace during the call.
USAGE
}

case "${1-}" in
  --help|--usage|-h)
    show_usage
    exit 0
    ;;
  "")
    ;;
  *)
    printf '%s\n' "repro-139-banish-gloss: unknown argument: $1" >&2
    exit 2
    ;;
esac

set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd -P)

export WIZARDRY_DIR=${WIZARDRY_DIR:-$repo_root}

if [ ! -d "$WIZARDRY_DIR/spells" ]; then
  printf '%s\n' "repro-139-banish-gloss: WIZARDRY_DIR invalid: $WIZARDRY_DIR" >&2
  exit 1
fi

gloss_file=$(mktemp "${TMPDIR:-/tmp}/wizardry-gloss.XXXXXX")
"$WIZARDRY_DIR/spells/.wizardry/generate-glosses" --output "$gloss_file"
. "$gloss_file"

if ! command -v banish >/dev/null 2>&1; then
  printf '%s\n' "repro-139-banish-gloss: banish command not found" >&2
  exit 1
fi

if ! type banish 2>/dev/null | grep -q "function"; then
  gloss_tmp=$(mktemp "${TMPDIR:-/tmp}/wizardry-banish-gloss.XXXXXX")
  cat >"$gloss_tmp" <<'GLOSS'
# Synthetic banish gloss wrapper (matches generate-glosses template)
banish() {
  _fw_spell="banish"
  _fw_words_used=0
  _fw_spell_home=${SPELLBOOK_DIR:-${HOME:-.}/.spellbook}

  for _fw_arg in "$@"; do
    case "$_fw_arg" in
      -*) break ;;
      *[!0-9]*) ;;
      *) break ;;
    esac

    _fw_candidate="${_fw_spell}-${_fw_arg}"
    _fw_words_used=$((_fw_words_used + 1))

    _fw_found=0
    for _fw_dir in "$WIZARDRY_DIR"/spells/*/; do
      _fw_path="${_fw_dir}${_fw_candidate}"
      if [ -f "$_fw_path" ] && grep -q "^# Uncastable pattern" "$_fw_path" 2>/dev/null; then
        shift "$_fw_words_used"
        . "$_fw_path"
        return $?
      fi
    done

    _fw_syn_target=""
    if [ -f "$_fw_spell_home/.synonyms" ]; then
      _fw_syn_target=$(grep "^${_fw_candidate}=" "$_fw_spell_home/.synonyms" 2>/dev/null | sed 's/^[^=]*=//' || true)
    fi
    if [ -z "$_fw_syn_target" ] && [ -f "$_fw_spell_home/.default-synonyms" ]; then
      _fw_syn_target=$(grep "^${_fw_candidate}=" "$_fw_spell_home/.default-synonyms" 2>/dev/null | sed 's/^[^=]*=//' || true)
    fi
    if [ -n "$_fw_syn_target" ]; then
      for _fw_dir in "$WIZARDRY_DIR"/spells/*/; do
        _fw_path="${_fw_dir}${_fw_syn_target}"
        if [ -f "$_fw_path" ] && grep -q "^# Uncastable pattern" "$_fw_path" 2>/dev/null; then
          shift "$_fw_words_used"
          . "$_fw_path"
          return $?
        fi
      done
      _fw_spell="$_fw_candidate"
      break
    fi

    _fw_spell="$_fw_candidate"
  done

  for _fw_dir in "$WIZARDRY_DIR"/spells/*/; do
    _fw_path="${_fw_dir}banish"
    if [ -f "$_fw_path" ] && grep -q "^# Uncastable pattern" "$_fw_path" 2>/dev/null; then
      . "$_fw_path"
      return $?
    fi
  done

  _fw_syn_target=""
  if [ -f "$_fw_spell_home/.synonyms" ]; then
    _fw_syn_target=$(grep "^banish=" "$_fw_spell_home/.synonyms" 2>/dev/null | sed 's/^[^=]*=//' || true)
  fi
  if [ -z "$_fw_syn_target" ] && [ -f "$_fw_spell_home/.default-synonyms" ]; then
    _fw_syn_target=$(grep "^banish=" "$_fw_spell_home/.default-synonyms" 2>/dev/null | sed 's/^[^=]*=//' || true)
  fi
  if [ -n "$_fw_syn_target" ]; then
    for _fw_dir in "$WIZARDRY_DIR"/spells/*/; do
      _fw_path="${_fw_dir}${_fw_syn_target}"
      if [ -f "$_fw_path" ] && grep -q "^# Uncastable pattern" "$_fw_path" 2>/dev/null; then
        . "$_fw_path"
        return $?
      fi
    done
  fi

  _fw_type_check=$(type "$_fw_spell" 2>/dev/null || printf '')
  case "$_fw_type_check" in
    *alias*)
      eval "$_fw_spell"
      ;;
    *)
      parse "$_fw_spell" "$@"
      ;;
  esac
}
GLOSS
  . "$gloss_tmp"
fi

xtrace=${BANISH_REPRO_XTRACE:-0}
if [ "$xtrace" -eq 1 ]; then
  set -x
fi

set +e
( banish 8 --only --no-tests --no-heal )
status=$?
if [ "$xtrace" -eq 1 ]; then
  set +x
fi

if [ "$status" -eq 139 ]; then
  printf '%s\n' "repro-139-banish-gloss: subshell exited with 139 (SIGSEGV)"
fi

exit "$status"
