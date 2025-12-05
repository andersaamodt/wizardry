#!/bin/sh
# Tests for the 'path' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_path_normalizes() {
  _run_spell spells/.imps/paths/path "./test"
  _assert_success
  # Should output an absolute path
  case "$OUTPUT" in
    /*) return 0 ;;
    *) TEST_FAILURE_REASON="should output absolute path"; return 1 ;;
  esac
}

test_path_handles_absolute_input() {
  _run_spell spells/.imps/paths/path "/tmp/test"
  _assert_success
  _assert_output_contains "/tmp/test"
}

_run_test_case "path normalizes relative path" test_path_normalizes
_run_test_case "path handles absolute input" test_path_handles_absolute_input

_finish_tests
