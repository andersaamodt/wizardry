#!/bin/sh
# Tests for is-submenu imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_returns_true_when_submenu() {
  run_cmd env WIZARDRY_SUBMENU=1 "$ROOT_DIR/spells/.imps/is-submenu"
  assert_success
}

test_returns_false_when_not_submenu() {
  run_cmd env -u WIZARDRY_SUBMENU "$ROOT_DIR/spells/.imps/is-submenu"
  assert_failure
}

run_test_case "is-submenu returns true when WIZARDRY_SUBMENU is set" test_returns_true_when_submenu
run_test_case "is-submenu returns false when WIZARDRY_SUBMENU is not set" test_returns_false_when_not_submenu

finish_tests
