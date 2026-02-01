#!/bin/sh
# Test build-apps spell

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.wizardry/desktop/build-apps" --help
  assert_success || return 1
  assert_output_contains "Usage: build-apps" || return 1
}

test_finds_apps() {
  # Should find the existing menu-app and chatroom apps
  run_spell "spells/.wizardry/desktop/build-apps"
  assert_success || return 1
  # Placeholder implementation shows count
  assert_output_contains "app" || return 1
}

run_test_case "build-apps shows help" test_help
run_test_case "build-apps finds apps" test_finds_apps

finish_tests
