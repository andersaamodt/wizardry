#!/bin/sh
# Tests for the 'lower' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_lower_converts() {
  _run_cmd sh -c "printf 'HELLO' | '$ROOT_DIR/spells/.imps/str/lower'"
  _assert_success
  _assert_output_contains "hello"
}

test_lower_handles_empty_input() {
  _run_cmd sh -c "printf '' | '$ROOT_DIR/spells/.imps/str/lower'"
  _assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

_run_test_case "lower converts to lowercase" test_lower_converts
_run_test_case "lower handles empty input" test_lower_handles_empty_input

_finish_tests
