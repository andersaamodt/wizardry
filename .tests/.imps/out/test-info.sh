#!/bin/sh
# Tests for the 'info' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_info_outputs_when_level_1() {
  WIZARDRY_LOG_LEVEL=1 run_spell spells/.imps/out/info "test info message"
  assert_success
  assert_output_contains "test info message"
}

test_info_silent_when_level_0() {
  WIZARDRY_LOG_LEVEL=0 run_spell spells/.imps/out/info "test info message"
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected no output, got: $OUTPUT"; return 1; }
}

test_info_default_level_0() {
  run_spell spells/.imps/out/info "test info message"
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected no output with default level, got: $OUTPUT"; return 1; }
}

run_test_case "info outputs when log level >= 1" test_info_outputs_when_level_1
run_test_case "info silent when log level 0" test_info_silent_when_level_0
run_test_case "info defaults to level 0" test_info_default_level_0

finish_tests
