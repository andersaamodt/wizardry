#!/bin/sh
# Tests for exit-label imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_returns_back_when_submenu() {
  run_cmd env WIZARDRY_SUBMENU=1 "$ROOT_DIR/spells/.imps/exit-label"
  assert_success
  assert_output_contains "Back"
}

test_returns_exit_when_not_submenu() {
  run_cmd env -u WIZARDRY_SUBMENU "$ROOT_DIR/spells/.imps/exit-label"
  assert_success
  assert_output_contains "Exit"
}

run_test_case "exit-label returns Back when called as submenu" test_returns_back_when_submenu
run_test_case "exit-label returns Exit when called directly" test_returns_exit_when_not_submenu

finish_tests
