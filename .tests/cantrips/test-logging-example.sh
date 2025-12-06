#!/bin/sh
# Tests for the 'logging-example' spell

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell spells/cantrips/logging-example --help
  _assert_success
  _assert_output_contains "Usage:"
}

test_default_output() {
  _run_spell spells/cantrips/logging-example
  _assert_success
  _assert_output_contains "Welcome to the logging example"
}

test_simulate_level_0() {
  WIZARDRY_LOG_LEVEL=0 _run_spell spells/cantrips/logging-example --simulate
  _assert_success
  _assert_output_contains "Multi-step process completed successfully"
  # At level 0, info/step/debug should not appear
  if printf '%s' "$OUTPUT" | grep -q "Starting multi-step"; then
    TEST_FAILURE_REASON="info message should not appear at level 0"
    return 1
  fi
}

test_simulate_level_1() {
  WIZARDRY_LOG_LEVEL=1 _run_spell spells/cantrips/logging-example --simulate
  _assert_success
  _assert_output_contains "Starting multi-step process"
  _assert_output_contains "Step 1:"
  _assert_output_contains "Multi-step process completed successfully"
}

test_simulate_level_2() {
  WIZARDRY_LOG_LEVEL=2 _run_spell spells/cantrips/logging-example --simulate
  _assert_success
  _assert_output_contains "Starting multi-step process"
  _assert_output_contains "Step 1:"
  # Debug output goes to stderr, check ERROR
  if ! printf '%s' "$ERROR" | grep -q "Current working directory"; then
    TEST_FAILURE_REASON="debug message should appear at level 2"
    return 1
  fi
}

_run_test_case "logging-example prints usage" test_help
_run_test_case "logging-example shows default output" test_default_output
_run_test_case "logging-example simulate at level 0" test_simulate_level_0
_run_test_case "logging-example simulate at level 1" test_simulate_level_1
_run_test_case "logging-example simulate at level 2" test_simulate_level_2

_finish_tests
