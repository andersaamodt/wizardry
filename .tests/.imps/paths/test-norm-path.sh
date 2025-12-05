#!/bin/sh
# Tests for the 'norm-path' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_norm_path_normalizes() {
  _run_spell spells/.imps/paths/norm-path "/tmp//test"
  _assert_success
  # Should normalize double slashes
  case "$OUTPUT" in
    *//*) TEST_FAILURE_REASON="should normalize double slashes"; return 1 ;;
  esac
}

test_norm_path_handles_simple_path() {
  _run_spell spells/.imps/paths/norm-path "/tmp/test"
  _assert_success
  _assert_output_contains "/tmp/test"
}

_run_test_case "norm-path normalizes path" test_norm_path_normalizes
_run_test_case "norm-path handles simple path" test_norm_path_handles_simple_path

_finish_tests
