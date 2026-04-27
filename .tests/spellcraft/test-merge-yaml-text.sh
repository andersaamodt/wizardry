#!/bin/sh
# Test coverage for merge-yaml-text spell:
# - Shows usage with --help
# - Is POSIX compliant

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/spellcraft/merge-yaml-text" --help
  assert_success || return 1
  assert_output_contains "Usage: merge-yaml-text" || return 1
}

test_help_h_flag() {
  run_spell "spells/spellcraft/merge-yaml-text" -h
  assert_success || return 1
  assert_output_contains "Usage: merge-yaml-text" || return 1
}

test_has_strict_mode() {
  # Verify the spell uses strict mode
  grep -q "set -eu" "$ROOT_DIR/spells/spellcraft/merge-yaml-text" || {
    TEST_FAILURE_REASON="spell does not use strict mode"
    return 1
  }
}

test_dry_run_accepts_flag_before_directory() {
  tmp=$(make_tempdir)
  dir="$tmp/case one"
  mkdir -p "$dir"
  printf '%s\n' 'title: Test' >"$dir/note.yaml"
  printf '%s\n' 'Body' >"$dir/note.txt"

  run_spell "spells/spellcraft/merge-yaml-text" --dry-run "$dir"
  assert_success || return 1
  assert_output_contains "---" || return 1
  assert_output_contains "title: Test" || return 1
  assert_output_contains "Body" || return 1

  [ -f "$dir/note.yaml" ] || { TEST_FAILURE_REASON="yaml file missing after dry-run"; return 1; }
  [ -f "$dir/note.txt" ] || { TEST_FAILURE_REASON="txt file missing after dry-run"; return 1; }
  yaml=$(cat "$dir/note.yaml")
  [ "$yaml" = "title: Test" ] || { TEST_FAILURE_REASON="dry-run modified yaml"; return 1; }
}

test_dry_run_preserves_existing_tempfile() {
  tmp=$(make_tempdir)
  dir="$tmp/case two"
  mkdir -p "$dir"
  printf '%s\n' 'title: Test' >"$dir/note.yaml"
  printf '%s\n' 'Body' >"$dir/note.txt"
  printf '%s\n' 'sentinel' >"$dir/tempfile.tmp"

  run_spell "spells/spellcraft/merge-yaml-text" "$dir" --dry-run
  assert_success || return 1

  [ -f "$dir/tempfile.tmp" ] || { TEST_FAILURE_REASON="existing tempfile.tmp was removed"; return 1; }
  sentinel=$(cat "$dir/tempfile.tmp")
  [ "$sentinel" = "sentinel" ] || { TEST_FAILURE_REASON="existing tempfile.tmp was modified"; return 1; }
}

run_test_case "merge-yaml-text shows usage text" test_help
run_test_case "merge-yaml-text shows usage with -h" test_help_h_flag
run_test_case "merge-yaml-text uses strict mode" test_has_strict_mode
run_test_case "merge-yaml-text accepts --dry-run before directory" test_dry_run_accepts_flag_before_directory
run_test_case "merge-yaml-text dry-run preserves existing tempfile" test_dry_run_preserves_existing_tempfile


# Test via source-then-invoke pattern  

finish_tests
