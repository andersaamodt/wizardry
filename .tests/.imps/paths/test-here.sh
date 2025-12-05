#!/bin/sh
# Tests for the 'here' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_here_outputs_directory() {
  _run_spell spells/.imps/paths/here
  _assert_success
  # Should output a path
  [ -d "$OUTPUT" ] || { TEST_FAILURE_REASON="should output directory"; return 1; }
}

test_here_outputs_normalized_path() {
  _run_spell spells/.imps/paths/here
  _assert_success
  case "$OUTPUT" in
    *///*) TEST_FAILURE_REASON="path should be normalized"; return 1 ;;
    *) return 0 ;;
  esac
}

_run_test_case "here outputs current directory" test_here_outputs_directory
_run_test_case "here outputs normalized path" test_here_outputs_normalized_path

_finish_tests
