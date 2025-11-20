#!/bin/sh
# Behavioral cases (derived from --help):
# - bind-tome requires a directory argument
# - bind-tome combines files into a tome
# - bind-tome refuses missing directories
# - bind-tome deletes pages when -d is provided
# - unbind-tome requires a file argument
# - unbind-tome splits the tome into sanitised files

set -eu

. "$(dirname "$0")/lib/test_common.sh"

require_arg_for_bind() {
  run_spell "spells/bind-tome"
  assert_failure || return 1
  assert_error_contains "Error: Please provide a folder path as an argument." || return 1
}

binds_pages_into_tome() {
  workdir=$(make_tempdir)
  mkdir -p "$workdir/pages"
  printf 'alpha rune\n' >"$workdir/pages/first"
  printf 'beta glyph\n' >"$workdir/pages/second"

  oldpwd=$(pwd)
  cd "$workdir"
  run_spell "spells/bind-tome" "pages"
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
  run_spell "spells/bind-tome" "-d"
  assert_failure || return 1
  assert_error_contains "Error: Please provide a folder path as an argument." || return 1

  run_spell "spells/bind-tome" "/no/such/place"
  assert_failure || return 1
  assert_error_contains "Error: '/no/such/place' is not a directory." || return 1
}

bind_deletes_pages_with_flag() {
  workdir=$(make_tempdir)
  mkdir -p "$workdir/pages"
  printf 'arcane\n' >"$workdir/pages/one"
  printf 'mystic\n' >"$workdir/pages/two"

  oldpwd=$(pwd)
  cd "$workdir"
  run_spell "spells/bind-tome" "-d" "pages"
  cd "$oldpwd"
  assert_success || return 1
  assert_output_contains "Text file created: pages.txt" || return 1
  assert_output_contains "Original files deleted." || return 1

  assert_path_missing "$workdir/pages/one" || return 1
  assert_path_missing "$workdir/pages/two" || return 1
}

require_arg_for_unbind() {
  run_spell "spells/unbind-tome"
  assert_failure || return 1
  assert_error_contains "Error: Please provide a file path as an argument." || return 1
}

unbind_splits_into_pages() {
  workdir=$(make_tempdir)
  cat <<'STORY' >"$workdir/story.txt"
First page
Symbols & sigils
Trailing space
STORY

  oldpwd=$(pwd)
  cd "$workdir"
  run_spell "spells/unbind-tome" "story.txt"
  cd "$oldpwd"
  assert_success || return 1

  pieces_dir="$workdir/story"
  assert_path_exists "$pieces_dir" || return 1
  assert_path_exists "$pieces_dir/First_page" || return 1
  assert_path_exists "$pieces_dir/Symbols__sigils" || return 1
  assert_path_exists "$pieces_dir/Trailing_space" || return 1
}

run_test_case "bind-tome requires a directory argument" require_arg_for_bind
run_test_case "bind-tome combines files into a tome" binds_pages_into_tome
run_test_case "bind-tome refuses missing directories" bind_requires_existing_directory
run_test_case "bind-tome deletes pages when -d is provided" bind_deletes_pages_with_flag
run_test_case "unbind-tome requires a file argument" require_arg_for_unbind
run_test_case "unbind-tome splits the tome into sanitised files" unbind_splits_into_pages

finish_tests
