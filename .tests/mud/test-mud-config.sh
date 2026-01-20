#!/bin/sh
# Tests for mud-config - MUD feature configuration management

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help_shows_usage() {
  run_spell "spells/mud/mud-config" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "get" || return 1
}

test_get_returns_disabled_by_default() {
  tmp=$(make_tempdir)
  run_cmd env SPELLBOOK_DIR="$tmp" "$ROOT_DIR/spells/mud/mud-config" get combat
  assert_success || return 1
  assert_output_contains "0" || return 1
}

test_set_enables_feature() {
  tmp=$(make_tempdir)
  run_cmd env SPELLBOOK_DIR="$tmp" "$ROOT_DIR/spells/mud/mud-config" set combat 1
  assert_success || return 1
  
  run_cmd env SPELLBOOK_DIR="$tmp" "$ROOT_DIR/spells/mud/mud-config" get combat
  assert_success || return 1
  assert_output_contains "1" || return 1
}

test_toggle_flips_state() {
  tmp=$(make_tempdir)
  
  # Toggle from disabled to enabled
  run_cmd env SPELLBOOK_DIR="$tmp" "$ROOT_DIR/spells/mud/mud-config" toggle combat
  assert_success || return 1
  assert_output_contains "1" || return 1
  
  # Toggle from enabled to disabled
  run_cmd env SPELLBOOK_DIR="$tmp" "$ROOT_DIR/spells/mud/mud-config" toggle combat
  assert_success || return 1
  assert_output_contains "0" || return 1
}

test_list_shows_all_features() {
  tmp=$(make_tempdir)
  run_cmd env SPELLBOOK_DIR="$tmp" "$ROOT_DIR/spells/mud/mud-config" list
  assert_success || return 1
  assert_output_contains "command-not-found=" || return 1
  assert_output_contains "touch-hook=" || return 1
  assert_output_contains "fantasy-theme=" || return 1
  assert_output_contains "inventory=" || return 1
  assert_output_contains "combat=" || return 1
}

test_invalid_value_rejected() {
  tmp=$(make_tempdir)
  run_cmd env SPELLBOOK_DIR="$tmp" "$ROOT_DIR/spells/mud/mud-config" set combat invalid
  assert_failure || return 1
  assert_error_contains "must be '1' or '0'" || return 1
}

run_test_case "mud-config --help shows usage" test_help_shows_usage
run_test_case "mud-config get returns disabled by default" test_get_returns_disabled_by_default
run_test_case "mud-config set enables feature" test_set_enables_feature
run_test_case "mud-config toggle flips state" test_toggle_flips_state
run_test_case "mud-config list shows all features" test_list_shows_all_features
run_test_case "mud-config set rejects invalid values" test_invalid_value_rejected

finish_tests
