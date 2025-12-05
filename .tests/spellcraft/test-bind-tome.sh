#!/bin/sh
# Behavioral cases (derived from --help):
# - bind-tome requires a directory argument
# - bind-tome combines files into a tome
# - bind-tome refuses missing directories
# - bind-tome deletes pages when -d is provided
# - bind-tome prints helpful usage text
# - bind-tome rejects invalid options and non-directories

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

bind_shows_usage() {
  run_spell "spells/spellcraft/bind-tome" --help
  assert_success || return 1
  assert_output_contains "Usage: bind-tome" || return 1
  assert_output_contains "Bind every file" || return 1
}

require_arg_for_bind() {
  run_spell "spells/spellcraft/bind-tome"
  assert_failure || return 1
  assert_error_contains "bind-tome: folder path required." || return 1
}

binds_pages_into_tome() {
  workdir=$(make_tempdir)
  mkdir -p "$workdir/pages"
  printf 'alpha rune\n' >"$workdir/pages/first"
  printf 'beta glyph\n' >"$workdir/pages/second"

  oldpwd=$(pwd)
  cd "$workdir"
  run_spell "spells/spellcraft/bind-tome" "pages"
  cd "$oldpwd"
  assert_success || return 1
  assert_output_contains "Text file created: pages.txt" || return 1

  [ -f "$workdir/pages.txt" ] || { TEST_FAILURE_REASON="tome not created"; return 1; }
  content=$(cat "$workdir/pages.txt")
  case "$content" in
    *"----- first -----"*"alpha rune"*"End of first"*"----- second -----"*"beta glyph"*"End of second"*) ;;
    *) TEST_FAILURE_REASON="tome content missing expected sections"; return 1 ;;
  esac
}

bind_requires_existing_directory() {
  run_spell "spells/spellcraft/bind-tome" "-d"
  assert_failure || return 1
  assert_error_contains "bind-tome: folder path required." || return 1

  run_spell "spells/spellcraft/bind-tome" "/no/such/place"
  assert_failure || return 1
  assert_error_contains "Error: '/no/such/place' is not a directory." || return 1

  file_path="$WIZARDRY_TMPDIR/bind-single.txt"
  printf 'lone page' >"$file_path"
  run_spell "spells/spellcraft/bind-tome" "$file_path"
  assert_failure || return 1
  assert_error_contains "is not a directory" || return 1
}

bind_rejects_unknown_option() {
  run_spell "spells/spellcraft/bind-tome" -z
  assert_failure || return 1
  assert_error_contains "Usage: bind-tome" || return 1
}

bind_deletes_pages_with_flag() {
  workdir=$(make_tempdir)
  mkdir -p "$workdir/pages"
  printf 'arcane\n' >"$workdir/pages/one"
  printf 'mystic\n' >"$workdir/pages/two"

  oldpwd=$(pwd)
  cd "$workdir"
  run_spell "spells/spellcraft/bind-tome" "-d" "pages"
  cd "$oldpwd"
  assert_success || return 1
  assert_output_contains "Text file created: pages.txt" || return 1
  assert_output_contains "Original files deleted." || return 1

  assert_path_missing "$workdir/pages/one" || return 1
  assert_path_missing "$workdir/pages/two" || return 1
}

run_test_case "bind-tome requires a directory argument" require_arg_for_bind
run_test_case "bind-tome combines files into a tome" binds_pages_into_tome
run_test_case "bind-tome refuses missing directories" bind_requires_existing_directory
run_test_case "bind-tome deletes pages when -d is provided" bind_deletes_pages_with_flag
run_test_case "bind-tome shows usage text" bind_shows_usage
run_test_case "bind-tome rejects unknown options" bind_rejects_unknown_option

finish_tests
