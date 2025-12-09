#!/bin/sh
# Test colors-available imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_colors_available_returns_true_when_wizardry_colors_available_is_1() {
  WIZARDRY_COLORS_AVAILABLE=1 _run_cmd "$ROOT_DIR/spells/.imps/cond/colors-available"
  _assert_success || return 1
}

test_colors_available_returns_false_when_wizardry_colors_available_is_0() {
  WIZARDRY_COLORS_AVAILABLE=0 _run_cmd "$ROOT_DIR/spells/.imps/cond/colors-available"
  _assert_failure || return 1
}

test_colors_available_checks_terminal_capability_when_unset() {
  # When WIZARDRY_COLORS_AVAILABLE is not set, it should check terminal
  # This test just ensures it doesn't crash
  env -u WIZARDRY_COLORS_AVAILABLE _run_cmd "$ROOT_DIR/spells/.imps/cond/colors-available"
  # Don't assert success/failure since it depends on test environment
  # Just ensure it runs without error in the test framework
  [ "$STATUS" -eq 0 ] || [ "$STATUS" -eq 1 ] || {
    TEST_FAILURE_REASON="expected exit code 0 or 1, got $STATUS"
    return 1
  }
}

_run_test_case "colors-available returns true when WIZARDRY_COLORS_AVAILABLE=1" test_colors_available_returns_true_when_wizardry_colors_available_is_1
_run_test_case "colors-available returns false when WIZARDRY_COLORS_AVAILABLE=0" test_colors_available_returns_false_when_wizardry_colors_available_is_0
_run_test_case "colors-available checks terminal when unset" test_colors_available_checks_terminal_capability_when_unset

_finish_tests
