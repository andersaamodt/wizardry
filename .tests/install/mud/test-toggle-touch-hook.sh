#!/bin/sh
# Tests for toggle-touch-hook - Toggle touch hook

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help_shows_usage() {
  _run_spell "spells/install/mud/toggle-touch-hook" --help
  _assert_success || return 1
  _assert_output_contains "Usage:" || return 1
  _assert_output_contains "touch hook" || return 1
}

test_toggle_enables_feature() {
  tmp=$(_make_tempdir)
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-touch-hook"
  _assert_success || return 1
  _assert_output_contains "enabled" || return 1
}

test_toggle_disables_feature() {
  tmp=$(_make_tempdir)
  # First enable
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-touch-hook"
  _assert_success || return 1
  
  # Then disable
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-touch-hook"
  _assert_success || return 1
  _assert_output_contains "disabled" || return 1
}

test_fails_when_mud_config_missing() {
  tmp=$(_make_tempdir)
  # Copy the toggle script to a temp location without mud-config
  cp "$ROOT_DIR/spells/install/mud/toggle-touch-hook" "$tmp/toggle-touch-hook"
  chmod +x "$tmp/toggle-touch-hook"
  
  _run_cmd env MUD_DIR="$tmp" "$tmp/toggle-touch-hook"
  _assert_failure || return 1
  _assert_error_contains "mud-config not found" || return 1
}

_run_test_case "toggle-touch-hook --help shows usage" test_help_shows_usage
_run_test_case "toggle-touch-hook enables feature" test_toggle_enables_feature
_run_test_case "toggle-touch-hook toggles feature off" test_toggle_disables_feature
_run_test_case "toggle-touch-hook fails when mud-config missing" test_fails_when_mud_config_missing

_finish_tests
