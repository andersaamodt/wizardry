#!/bin/sh
# Tests for the 'clear-traps' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_clear_traps_succeeds() {
  run_spell spells/.imps/sys/clear-traps
  assert_success
}

test_clear_traps_produces_no_output() {
  run_spell spells/.imps/sys/clear-traps
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected no output, got: $OUTPUT"; return 1; }
}

run_test_case "clear-traps clears traps successfully" test_clear_traps_succeeds
run_test_case "clear-traps produces no output" test_clear_traps_produces_no_output

finish_tests
