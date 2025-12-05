#!/bin/sh
# Tests for the 'now' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_now_outputs_timestamp() {
  run_spell spells/.imps/sys/now
  assert_success
  # Should output a number (Unix timestamp)
  case "$OUTPUT" in
    *[!0-9]*) TEST_FAILURE_REASON="should output number"; return 1 ;;
  esac
}

test_now_returns_positive_value() {
  run_spell spells/.imps/sys/now
  assert_success
  [ "$OUTPUT" -gt 0 ] || { TEST_FAILURE_REASON="timestamp should be positive"; return 1; }
}

run_test_case "now outputs timestamp" test_now_outputs_timestamp
run_test_case "now returns positive value" test_now_returns_positive_value

finish_tests
