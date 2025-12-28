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
  run_spell spells/cantrips/logging-example --help
  assert_success
  assert_output_contains "Usage:"
}

test_default_output() {
  skip-if-compiled || return $?
  run_spell spells/cantrips/logging-example
  assert_success
  assert_output_contains "Welcome to the logging example"
}

test_simulate_level_0() {
  WIZARDRY_LOG_LEVEL=0 run_spell spells/cantrips/logging-example --simulate
  assert_success
  assert_output_contains "Multi-step process completed successfully"
  # At level 0, info/step/debug should not appear
  if printf '%s' "$OUTPUT" | grep -q "Starting multi-step"; then
    TEST_FAILURE_REASON="info message should not appear at level 0"
    return 1
  fi
}

test_simulate_level_1() {
  skip-if-compiled || return $?
  WIZARDRY_LOG_LEVEL=1 run_spell spells/cantrips/logging-example --simulate
  assert_success
  assert_output_contains "Starting multi-step process"
  assert_output_contains "Step 1:"
  assert_output_contains "Multi-step process completed successfully"
}

test_simulate_level_2() {
  skip-if-compiled || return $?
  WIZARDRY_LOG_LEVEL=2 run_spell spells/cantrips/logging-example --simulate
  assert_success
  assert_output_contains "Starting multi-step process"
  assert_output_contains "Step 1:"
  # Debug output goes to stderr with DEBUG: prefix
  assert_error_contains "DEBUG:"
  assert_error_contains "Current working directory"
}

run_test_case "logging-example prints usage" test_help
run_test_case "logging-example shows default output" test_default_output
run_test_case "logging-example simulate at level 0" test_simulate_level_0
run_test_case "logging-example simulate at level 1" test_simulate_level_1
run_test_case "logging-example simulate at level 2" test_simulate_level_2


# Test via source-then-invoke pattern  
