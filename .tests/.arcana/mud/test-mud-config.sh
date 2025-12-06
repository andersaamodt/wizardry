#!/bin/sh
# Tests for mud-config - MUD feature configuration management

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help_shows_usage() {
  _run_spell "spells/.arcana/mud/mud-config" --help
  _assert_success || return 1
  _assert_output_contains "Usage:" || return 1
  _assert_output_contains "get" || return 1
}

test_get_returns_disabled_by_default() {
  tmp=$(_make_tempdir)
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/mud-config" get combat
  _assert_success || return 1
  _assert_output_contains "0" || return 1
}

test_set_enables_feature() {
  tmp=$(_make_tempdir)
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/mud-config" set combat 1
  _assert_success || return 1
  
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/mud-config" get combat
  _assert_success || return 1
  _assert_output_contains "1" || return 1
}

test_toggle_flips_state() {
  tmp=$(_make_tempdir)
  
  # Toggle from disabled to enabled
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/mud-config" toggle combat
  _assert_success || return 1
  _assert_output_contains "1" || return 1
  
  # Toggle from enabled to disabled
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/mud-config" toggle combat
  _assert_success || return 1
  _assert_output_contains "0" || return 1
}

test_list_shows_all_features() {
  tmp=$(_make_tempdir)
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/mud-config" list
  _assert_success || return 1
  _assert_output_contains "command-not-found=" || return 1
  _assert_output_contains "touch-hook=" || return 1
  _assert_output_contains "fantasy-theme=" || return 1
  _assert_output_contains "inventory=" || return 1
  _assert_output_contains "combat=" || return 1
}

test_invalid_value_rejected() {
  tmp=$(_make_tempdir)
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/mud-config" set combat invalid
  _assert_failure || return 1
  _assert_error_contains "must be '1' or '0'" || return 1
}

_run_test_case "mud-config --help shows usage" test_help_shows_usage
_run_test_case "mud-config get returns disabled by default" test_get_returns_disabled_by_default
_run_test_case "mud-config set enables feature" test_set_enables_feature
_run_test_case "mud-config toggle flips state" test_toggle_flips_state
_run_test_case "mud-config list shows all features" test_list_shows_all_features
_run_test_case "mud-config set rejects invalid values" test_invalid_value_rejected

_finish_tests
