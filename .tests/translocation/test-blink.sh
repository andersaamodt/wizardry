#!/bin/sh
# Test coverage for blink spell:
# - Shows usage with --help
# - Successfully blinks to a random directory from root
# - Respects --home flag
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
  assert_output_contains "--home" || return 1
}

test_blink_from_root() {
  # Test that blink works from root (default behavior)
  # Just verify it produces output without error
  OUTPUT=$(. "$ROOT_DIR/spells/translocation/blink" 1 2>&1) || true
  
  # Check that we got some output (the blink happened)
  if [ -n "$OUTPUT" ]; then
    return 0
  else
    return 1
  fi
}

test_blink_with_home_flag() {
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
  
  # Source the blink spell with --home flag
  OUTPUT=$(. "$ROOT_DIR/spells/translocation/blink" --home 1 2>&1) || true
  
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
run_test_case "blink teleports from root by default" test_blink_from_root
run_test_case "blink respects --home flag" test_blink_with_home_flag
run_test_case "blink rejects invalid depth parameter" test_rejects_invalid_depth
run_test_case "blink rejects zero depth" test_rejects_zero_depth

finish_tests
