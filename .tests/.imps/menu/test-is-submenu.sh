#!/bin/sh
# Tests for is-submenu imp
# Since WIZARDRY_SUBMENU is deprecated (against project policy to use env vars),
# is-submenu now always returns false (exit 1).

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_always_returns_false() {
  # is-submenu always returns false since submenu detection is not reliably
  # possible without using environment variables
  run_cmd "$ROOT_DIR/spells/.imps/menu/is-submenu"
  assert_failure
}

test_ignores_submenu_env() {
  # Even with WIZARDRY_SUBMENU set, is-submenu returns false
  run_cmd env WIZARDRY_SUBMENU=1 "$ROOT_DIR/spells/.imps/menu/is-submenu"
  assert_failure
}

run_test_case "is-submenu always returns false" test_always_returns_false
run_test_case "is-submenu ignores WIZARDRY_SUBMENU env var" test_ignores_submenu_env

finish_tests
