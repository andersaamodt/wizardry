#!/bin/sh
# Tests for toggle-all-mud - Enable/disable all MUD features at once

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"
test_help_shows_usage() {
  run_spell "spells/.arcana/mud/toggle-all-mud" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "--enable" || return 1
  assert_output_contains "--disable" || return 1
}
test_enable_flag_enables_all() {
  tmp=$(make_tempdir)
  run_cmd env SPELLBOOK_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/toggle-all-mud" --enable
  assert_output_contains "All MUD features enabled" || return 1
  
  # Verify all features are enabled (avatar and touch-hook)
  run_cmd env SPELLBOOK_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/mud-config" list
  assert_output_contains "avatar=1" || return 1
  assert_output_contains "touch-hook=1" || return 1
test_disable_flag_disables_all() {
  # First enable all features
  # Then disable all
  run_cmd env SPELLBOOK_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/toggle-all-mud" --disable
  assert_output_contains "All MUD features disabled" || return 1
  # Verify all features are disabled (avatar and touch-hook)
  assert_output_contains "avatar=0" || return 1
  assert_output_contains "touch-hook=0" || return 1
test_auto_toggle_enables_when_any_disabled() {
  # Start with all disabled (default state)
  run_cmd env SPELLBOOK_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/toggle-all-mud"
test_auto_toggle_disables_when_all_enabled() {
  # First enable all
  # Auto-toggle should disable
run_test_case "toggle-all-mud --help shows usage" test_help_shows_usage
run_test_case "toggle-all-mud --enable enables all features" test_enable_flag_enables_all
run_test_case "toggle-all-mud --disable disables all features" test_disable_flag_disables_all
run_test_case "toggle-all-mud auto-enables when any disabled" test_auto_toggle_enables_when_any_disabled
run_test_case "toggle-all-mud auto-disables when all enabled" test_auto_toggle_disables_when_all_enabled
finish_tests
