#!/bin/sh
# Behavioral cases (derived from --help):
# - unbind-tome requires a file argument
# - unbind-tome splits the tome into sanitised files

set -eu

. "$(dirname "$0")/lib/test_common.sh"

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

run_test_case "unbind-tome requires a file argument" require_arg_for_unbind
run_test_case "unbind-tome splits the tome into sanitised files" unbind_splits_into_pages

finish_tests
