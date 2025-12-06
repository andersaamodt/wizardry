#!/bin/sh
# Tests for the 'debug' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_debug_outputs_when_level_2() {
  WIZARDRY_LOG_LEVEL=2 _run_spell spells/.imps/out/debug "debug message"
  _assert_success
  _assert_error_contains "debug message"
}

test_debug_silent_when_level_1() {
  WIZARDRY_LOG_LEVEL=1 _run_spell spells/.imps/out/debug "debug message"
  _assert_success
  [ -z "$ERROR" ] || { TEST_FAILURE_REASON="expected no output at level 1, got: $ERROR"; return 1; }
}

test_debug_silent_when_level_0() {
  WIZARDRY_LOG_LEVEL=0 _run_spell spells/.imps/out/debug "debug message"
  _assert_success
  [ -z "$ERROR" ] || { TEST_FAILURE_REASON="expected no output at level 0, got: $ERROR"; return 1; }
}

test_debug_default_level_0() {
  _run_spell spells/.imps/out/debug "debug message"
  _assert_success
  [ -z "$ERROR" ] || { TEST_FAILURE_REASON="expected no output with default level, got: $ERROR"; return 1; }
}

_run_test_case "debug outputs when log level >= 2" test_debug_outputs_when_level_2
_run_test_case "debug silent when log level 1" test_debug_silent_when_level_1
_run_test_case "debug silent when log level 0" test_debug_silent_when_level_0
_run_test_case "debug defaults to level 0" test_debug_default_level_0

_finish_tests
