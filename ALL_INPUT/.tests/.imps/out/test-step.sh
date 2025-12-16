#!/bin/sh
# Tests for the 'step' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_step_outputs_when_level_1() {
  WIZARDRY_LOG_LEVEL=1 _run_spell spells/.imps/out/step "step 1 of 3"
  _assert_success
  _assert_output_contains "step 1 of 3"
}

test_step_silent_when_level_0() {
  WIZARDRY_LOG_LEVEL=0 _run_spell spells/.imps/out/step "step 1 of 3"
  _assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected no output, got: $OUTPUT"; return 1; }
}

test_step_default_level_0() {
  _run_spell spells/.imps/out/step "step 1 of 3"
  _assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected no output with default level, got: $OUTPUT"; return 1; }
}

_run_test_case "step outputs when log level >= 1" test_step_outputs_when_level_1
_run_test_case "step silent when log level 0" test_step_silent_when_level_0
_run_test_case "step defaults to level 0" test_step_default_level_0

_finish_tests
