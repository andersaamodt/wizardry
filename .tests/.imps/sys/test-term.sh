#!/bin/sh
# Tests for the 'term' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_term_detects() {
  # This is tricky to test since we may or may not be in a terminal
  _run_spell spells/.imps/sys/term
  # Just verify it exits without error
  [ "$STATUS" -eq 0 ] || [ "$STATUS" -eq 1 ]
}

test_term_returns_valid_status() {
  _run_spell spells/.imps/sys/term
  # Status should be either 0 (in terminal) or 1 (not in terminal)
  [ "$STATUS" -eq 0 ] || [ "$STATUS" -eq 1 ] || { TEST_FAILURE_REASON="status should be 0 or 1"; return 1; }
}

_run_test_case "term detects terminal" test_term_detects
_run_test_case "term returns valid status" test_term_returns_valid_status

_finish_tests
