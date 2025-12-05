#!/bin/sh
# Tests for exit-label imp
# Since WIZARDRY_SUBMENU is deprecated (against project policy to use env vars),
# exit-label now always returns "Exit".

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_returns_exit_always() {
  _run_cmd "$ROOT_DIR/spells/.imps/menu/exit-label"
  _assert_success
  _assert_output_contains "Exit"
}

test_ignores_submenu_env() {
  # Even with WIZARDRY_SUBMENU set, exit-label returns "Exit"
  _run_cmd env WIZARDRY_SUBMENU=1 "$ROOT_DIR/spells/.imps/menu/exit-label"
  _assert_success
  _assert_output_contains "Exit"
}

_run_test_case "exit-label always returns Exit" test_returns_exit_always
_run_test_case "exit-label ignores WIZARDRY_SUBMENU env var" test_ignores_submenu_env

_finish_tests
