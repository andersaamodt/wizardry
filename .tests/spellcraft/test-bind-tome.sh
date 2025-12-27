#!/bin/sh
# Behavioral cases (derived from --help):
# - bind-tome requires a directory argument
# - bind-tome combines files into a tome
# - bind-tome refuses missing directories
# - bind-tome deletes pages when -d is provided
# - bind-tome prints helpful usage text
# - bind-tome rejects invalid options and non-directories

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

bind_shows_usage() {
  _run_spell "spells/spellcraft/bind-tome" --help
  _assert_success || return 1
  _assert_output_contains "Usage: bind-tome" || return 1
  _assert_output_contains "Bind every file" || return 1
}

require_arg_for_bind() {
  _run_spell "spells/spellcraft/bind-tome"
  _assert_failure || return 1
  _assert_error_contains "bind-tome: folder path required." || return 1
}

binds_pages_into_tome() {
  workdir=$(_make_tempdir)
  mkdir -p "$workdir/pages"
  printf 'alpha rune\n' >"$workdir/pages/first"
  printf 'beta glyph\n' >"$workdir/pages/second"

  oldpwd=$(pwd)
  cd "$workdir"
  _run_spell "spells/spellcraft/bind-tome" "pages"
  cd "$oldpwd"
  _assert_success || return 1
  _assert_output_contains "Text file created: pages.txt" || return 1

  [ -f "$workdir/pages.txt" ] || { TEST_FAILURE_REASON="tome not created"; return 1; }
  content=$(cat "$workdir/pages.txt")
  # New centered format: # -------- filename --------
  case "$content" in
    *"# "*" first "*|*"# -"*"- first -"*) ;;
    *) TEST_FAILURE_REASON="tome content missing first separator"; return 1 ;;
  esac
  case "$content" in
    *"alpha rune"*) ;;
    *) TEST_FAILURE_REASON="tome content missing first content"; return 1 ;;
  esac
  case "$content" in
    *"# "*" second "*|*"# -"*"- second -"*) ;;
    *) TEST_FAILURE_REASON="tome content missing second separator"; return 1 ;;
  esac
  case "$content" in
    *"beta glyph"*) ;;
    *) TEST_FAILURE_REASON="tome content missing second content"; return 1 ;;
  esac
}

bind_requires_existing_directory() {
  _run_spell "spells/spellcraft/bind-tome" "-d"
  _assert_failure || return 1
  _assert_error_contains "bind-tome: folder path required." || return 1

  _run_spell "spells/spellcraft/bind-tome" "/no/such/place"
  _assert_failure || return 1
  _assert_error_contains "Error: '/no/such/place' is not a directory." || return 1

  file_path="$WIZARDRY_TMPDIR/bind-single.txt"
  printf 'lone page' >"$file_path"
  _run_spell "spells/spellcraft/bind-tome" "$file_path"
  _assert_failure || return 1
  _assert_error_contains "is not a directory" || return 1
}

bind_rejects_unknown_option() {
  _run_spell "spells/spellcraft/bind-tome" -z
  _assert_failure || return 1
  _assert_error_contains "Usage: bind-tome" || return 1
}

bind_deletes_pages_with_flag() {
  workdir=$(_make_tempdir)
  mkdir -p "$workdir/pages"
  printf 'arcane\n' >"$workdir/pages/one"
  printf 'mystic\n' >"$workdir/pages/two"

  oldpwd=$(pwd)
  cd "$workdir"
  _run_spell "spells/spellcraft/bind-tome" "-d" "pages"
  cd "$oldpwd"
  _assert_success || return 1
  _assert_output_contains "Text file created: pages.txt" || return 1
  _assert_output_contains "Original files deleted." || return 1

  _assert_path_missing "$workdir/pages/one" || return 1
  _assert_path_missing "$workdir/pages/two" || return 1
}

_run_test_case "bind-tome requires a directory argument" require_arg_for_bind
_run_test_case "bind-tome combines files into a tome" binds_pages_into_tome
_run_test_case "bind-tome refuses missing directories" bind_requires_existing_directory
_run_test_case "bind-tome deletes pages when -d is provided" bind_deletes_pages_with_flag
_run_test_case "bind-tome shows usage text" bind_shows_usage
_run_test_case "bind-tome rejects unknown options" bind_rejects_unknown_option


# Test via source-then-invoke pattern  
