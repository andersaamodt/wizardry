#!/bin/sh
# Tests for exit-label imp
# Since WIZARDRY_SUBMENU is deprecated (against project policy to use env vars),
# exit-label now always returns "Exit".

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_returns_exit_always() {
  run_cmd "$ROOT_DIR/spells/.imps/menu/exit-label"
  assert_success
  assert_output_contains "Exit"
}

test_ignores_submenu_env() {
  # Even with WIZARDRY_SUBMENU set, exit-label returns "Exit"
  run_cmd env WIZARDRY_SUBMENU=1 "$ROOT_DIR/spells/.imps/menu/exit-label"
  assert_success
  assert_output_contains "Exit"
}

run_test_case "exit-label always returns Exit" test_returns_exit_always
run_test_case "exit-label ignores WIZARDRY_SUBMENU env var" test_ignores_submenu_env

finish_tests
