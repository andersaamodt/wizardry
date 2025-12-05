#!/bin/sh
# Tests for is-submenu imp
# Since WIZARDRY_SUBMENU is deprecated (against project policy to use env vars),
# is-submenu now always returns false (exit 1).

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

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
