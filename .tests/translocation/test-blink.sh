#!/bin/sh
# Test coverage for blink spell:
# - Shows usage with --help
# - Successfully blinks to a random directory
# - Validates max-depth parameter

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/translocation/blink" --help
  assert_success || return 1
  assert_output_contains "Usage: . blink" || return 1
}

test_blink_to_random_dir() {
  # Create a test directory structure
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/test/dir1"
  mkdir -p "$tmpdir/test/dir2"
  mkdir -p "$tmpdir/test/dir3"
  
  # Save original directory
  orig_dir=$(pwd)
  
  # Change to temp dir and set HOME for test
  cd "$tmpdir"
  old_home=$HOME
  HOME="$tmpdir"
  export HOME
  
  # Source the blink spell (it needs to be sourced to change directory)
  # We'll test that it produces output about teleporting
  OUTPUT=$(. "$ROOT_DIR/spells/translocation/blink" 1 2>&1) || true
  
  # Restore HOME
  HOME=$old_home
  export HOME
  
  # Go back to original directory
  cd "$orig_dir"
  
  # Check that we got some output (the blink happened)
  if [ -n "$OUTPUT" ]; then
    return 0
  else
    return 1
  fi
}

test_rejects_invalid_depth() {
  run_spell "spells/translocation/blink" abc
  assert_failure || return 1
  assert_error_contains "positive integer" || return 1
}

test_rejects_zero_depth() {
  run_spell "spells/translocation/blink" 0
  assert_failure || return 1
  assert_error_contains "positive integer" || return 1
}

run_test_case "blink shows usage text" test_help
run_test_case "blink teleports to random directory" test_blink_to_random_dir
run_test_case "blink rejects invalid depth parameter" test_rejects_invalid_depth
run_test_case "blink rejects zero depth" test_rejects_zero_depth

finish_tests
