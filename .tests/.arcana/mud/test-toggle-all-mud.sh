#!/bin/sh
# Tests for toggle-all-mud - Enable/disable all MUD features at once

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help_shows_usage() {
  _run_spell "spells/.arcana/mud/toggle-all-mud" --help
  _assert_success || return 1
  _assert_output_contains "Usage:" || return 1
  _assert_output_contains "--enable" || return 1
  _assert_output_contains "--disable" || return 1
}

test_enable_flag_enables_all() {
  tmp=$(_make_tempdir)
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/toggle-all-mud" --enable
  _assert_success || return 1
  _assert_output_contains "All MUD features enabled" || return 1
  
  # Verify all features are enabled
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/mud-config" list
  _assert_success || return 1
  _assert_output_contains "command-not-found=1" || return 1
  _assert_output_contains "touch-hook=1" || return 1
  _assert_output_contains "fantasy-theme=1" || return 1
  _assert_output_contains "inventory=1" || return 1
  _assert_output_contains "combat=1" || return 1
}

test_disable_flag_disables_all() {
  tmp=$(_make_tempdir)
  # First enable all features
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/toggle-all-mud" --enable
  _assert_success || return 1
  
  # Then disable all
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/toggle-all-mud" --disable
  _assert_success || return 1
  _assert_output_contains "All MUD features disabled" || return 1
  
  # Verify all features are disabled
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/mud-config" list
  _assert_success || return 1
  _assert_output_contains "command-not-found=0" || return 1
  _assert_output_contains "touch-hook=0" || return 1
  _assert_output_contains "fantasy-theme=0" || return 1
  _assert_output_contains "inventory=0" || return 1
  _assert_output_contains "combat=0" || return 1
}

test_auto_toggle_enables_when_any_disabled() {
  tmp=$(_make_tempdir)
  # Start with all disabled (default state)
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/toggle-all-mud"
  _assert_success || return 1
  _assert_output_contains "All MUD features enabled" || return 1
}

test_auto_toggle_disables_when_all_enabled() {
  tmp=$(_make_tempdir)
  # First enable all
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/toggle-all-mud" --enable
  _assert_success || return 1
  
  # Auto-toggle should disable
  _run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/toggle-all-mud"
  _assert_success || return 1
  _assert_output_contains "All MUD features disabled" || return 1
}

_run_test_case "toggle-all-mud --help shows usage" test_help_shows_usage
_run_test_case "toggle-all-mud --enable enables all features" test_enable_flag_enables_all
_run_test_case "toggle-all-mud --disable disables all features" test_disable_flag_disables_all
_run_test_case "toggle-all-mud auto-enables when any disabled" test_auto_toggle_enables_when_any_disabled
_run_test_case "toggle-all-mud auto-disables when all enabled" test_auto_toggle_disables_when_all_enabled

_finish_tests
