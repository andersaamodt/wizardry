#!/bin/sh
# Tests for exit-label imp
# exit-label returns "Back" when WIZARDRY_SUBMENU=1 (nested menu), "Exit" otherwise.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_returns_exit_at_top_level() {
  run_cmd "$ROOT_DIR/spells/.imps/exit-label"
  assert_success
  assert_output_contains "Exit"
}

test_returns_back_when_nested() {
  # With WIZARDRY_SUBMENU=1 set, exit-label returns "Back"
  run_cmd env WIZARDRY_SUBMENU=1 "$ROOT_DIR/spells/.imps/exit-label"
  assert_success
  assert_output_contains "Back"
}

run_test_case "exit-label returns Exit at top level" test_returns_exit_at_top_level
run_test_case "exit-label returns Back when nested" test_returns_back_when_nested

finish_tests
