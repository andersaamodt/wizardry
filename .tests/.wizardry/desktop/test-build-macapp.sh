#!/bin/sh
# Test build-macapp spell

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.wizardry/desktop/build-macapp" --help
  assert_success || return 1
  assert_output_contains "Usage: build-macapp" || return 1
}

test_requires_app_name() {
  run_spell "spells/.wizardry/desktop/build-macapp"
  assert_failure || return 1
  assert_error_contains "requires app name" || return 1
}

test_validates_app_exists() {
  run_spell "spells/.wizardry/desktop/build-macapp" "nonexistent-app"
  assert_failure || return 1
  assert_error_contains "invalid app" || return 1
}

test_accepts_valid_app() {
  # The repository has menu-app, should be accepted (placeholder just validates)
  run_spell "spells/.wizardry/desktop/build-macapp" "menu-app"
  assert_success || return 1
  assert_output_contains "App validated" || return 1
}

run_test_case "build-macapp shows help" test_help
run_test_case "build-macapp requires app name" test_requires_app_name
run_test_case "build-macapp validates app exists" test_validates_app_exists
run_test_case "build-macapp accepts valid app" test_accepts_valid_app

finish_tests
