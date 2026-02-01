#!/bin/sh
# Test launch-app spell

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/desktop/launch-app" --help
  assert_success || return 1
  assert_output_contains "Usage: launch-app" || return 1
}

test_launch_requires_app_name() {
  run_spell "spells/desktop/launch-app"
  assert_failure || return 1
  assert_error_contains "requires app name" || return 1
}

test_launch_validates_app() {
  # The repository already has menu-app
  run_spell "spells/desktop/launch-app" "menu-app"
  assert_success || return 1
  assert_output_contains "App validated" || return 1
}

test_launch_rejects_invalid_app() {
  run_spell "spells/desktop/launch-app" "nonexistent-app"
  assert_failure || return 1
  assert_error_contains "invalid app" || return 1
}

run_test_case "launch-app shows help" test_help
run_test_case "launch-app requires app name" test_launch_requires_app_name
run_test_case "launch-app validates app" test_launch_validates_app
run_test_case "launch-app rejects invalid app" test_launch_rejects_invalid_app

finish_tests
