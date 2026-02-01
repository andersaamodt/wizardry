#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_shows_help() {
  _run_spell "spells/.wizardry/desktop/app-launcher" --help
  _assert_success && _assert_output_contains "Usage:"
}

test_requires_app_name() {
  _run_spell "spells/.wizardry/desktop/app-launcher"
  _assert_failure
}

test_validates_app_exists() {
  _run_spell "spells/.wizardry/desktop/app-launcher" "nonexistent-app"
  _assert_failure
}

test_accepts_valid_app() {
  _run_spell "spells/.wizardry/desktop/app-launcher" "menu-app"
  _assert_success
}

_run_test_case "shows help" test_shows_help
_run_test_case "requires app name" test_requires_app_name
_run_test_case "validates app exists" test_validates_app_exists
_run_test_case "accepts valid app" test_accepts_valid_app

_finish_tests
