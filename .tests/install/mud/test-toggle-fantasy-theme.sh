#!/bin/sh
# Tests for toggle-fantasy-theme - Toggle fantasy theme

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help_shows_usage() {
  run_spell "spells/install/mud/toggle-fantasy-theme" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "fantasy theme" || return 1
}

test_toggle_enables_feature() {
  tmp=$(make_tempdir)
  run_cmd env WIZARDRY_MUD_CONFIG_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-fantasy-theme"
  assert_success || return 1
  assert_output_contains "enabled" || return 1
}

run_test_case "toggle-fantasy-theme --help shows usage" test_help_shows_usage
run_test_case "toggle-fantasy-theme enables feature" test_toggle_enables_feature

finish_tests
