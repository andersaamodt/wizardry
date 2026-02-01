#!/bin/sh
# Test list-apps spell

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/desktop/list-apps" --help
  assert_success || return 1
  assert_output_contains "Usage: list-apps" || return 1
}

test_list_apps_shows_valid_apps() {
  # The repository already has menu-app, test should find it
  run_spell "spells/desktop/list-apps"
  assert_success || return 1
  assert_output_contains "menu-app" || return 1
}

run_test_case "list-apps shows help" test_help
run_test_case "list-apps shows valid apps" test_list_apps_shows_valid_apps

finish_tests
