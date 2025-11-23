#!/bin/sh
# Behavioral cases (derived from --help):
# - unbind-tome requires a file argument
# - unbind-tome splits the tome into sanitised files
# - unbind-tome prints helpful usage text
# - unbind-tome refuses non-file inputs and existing destination folders
# - unbind-tome invents names for blank pages

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

unbind_shows_usage() {
  run_spell "spells/spellcraft/unbind-tome" --help
  assert_success || return 1
  assert_output_contains "Usage: unbind-tome" || return 1
  assert_output_contains "Split a bound tome" || return 1
}

require_arg_for_unbind() {
  run_spell "spells/spellcraft/unbind-tome"
  assert_failure || return 1
  assert_error_contains "Error: Please provide a file path as an argument." || return 1
}

unbind_requires_a_file() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/dir"

  run_spell "spells/spellcraft/unbind-tome" "$tmpdir/dir"
  assert_failure || return 1
  assert_error_contains "is not a file" || return 1
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
  run_spell "spells/spellcraft/unbind-tome" "story.txt"
  cd "$oldpwd"
  assert_success || return 1

  pieces_dir="$workdir/story"
  assert_path_exists "$pieces_dir" || return 1
  assert_path_exists "$pieces_dir/First_page" || return 1
  assert_path_exists "$pieces_dir/Symbols__sigils" || return 1
  assert_path_exists "$pieces_dir/Trailing_space" || return 1
}

unbind_avoids_clobbering_existing_folder() {
  workdir=$(make_tempdir)
  mkdir -p "$workdir/story" "$workdir/story1"
  printf 'First\nSecond\n' >"$workdir/story.txt"

  oldpwd=$(pwd)
  cd "$workdir"
  run_spell "spells/spellcraft/unbind-tome" "story.txt"
  cd "$oldpwd"
  assert_success || return 1

  assert_path_exists "$workdir/story2" || return 1
  assert_path_exists "$workdir/story2/First" || return 1
  assert_path_exists "$workdir/story2/Second" || return 1
}

unbind_names_blank_pages() {
  workdir=$(make_tempdir)
  cat <<'STORY' >"$workdir/blanky.txt"

Titled page

STORY

  RUN_CMD_WORKDIR="$workdir" run_spell "spells/spellcraft/unbind-tome" "$workdir/blanky.txt"
  assert_success || return 1

  assert_path_exists "$workdir/blanky/page_1" || return 1
  assert_path_exists "$workdir/blanky/Titled_page" || return 1
  assert_path_exists "$workdir/blanky/page_3" || return 1
}

run_test_case "unbind-tome requires a file argument" require_arg_for_unbind
run_test_case "unbind-tome splits the tome into sanitised files" unbind_splits_into_pages
run_test_case "unbind-tome shows usage text" unbind_shows_usage
run_test_case "unbind-tome refuses non-file inputs" unbind_requires_a_file
run_test_case "unbind-tome avoids clobbering existing folders" unbind_avoids_clobbering_existing_folder
run_test_case "unbind-tome invents names for blank pages" unbind_names_blank_pages

finish_tests
