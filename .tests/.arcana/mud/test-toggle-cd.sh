#!/bin/sh
# Tests for toggle-cd spell (settings-based)
# toggle-cd manages the cd-look=1 setting in ~/.spellbook/.mud/config

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"
test_toggle_cd_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/mud/toggle-cd" ]
}
test_toggle_cd_help_shows_usage() {
  run_spell spells/.arcana/mud/toggle-cd --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "toggle" || return 1
test_toggle_cd_enables_when_disabled() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  
  
  # Start with disabled (no cd-look=1 line)
printf "other-setting=1\n" > "$tmpdir/.spellbook/.mud/config"
  # Run toggle-cd directly (not through run_cmd sandbox)
  output=$(env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/.arcana/mud/toggle-cd" 2>&1)
  # Check output
  case "$output" in
    *enabled*)
      ;;
    *)
      TEST_FAILURE_REASON="Output missing 'enabled': $output"
      return 1
  esac
  # Verify setting was added
  if ! grep -q "^cd-look=1$" "$tmpdir/.spellbook/.mud/config"; then
    TEST_FAILURE_REASON="cd-look=1 not found in config after enable"
    return 1
  fi
test_toggle_cd_disables_when_enabled() {
  # Start with enabled
printf "cd-look=1\nother-setting=1\n" > "$tmpdir/.spellbook/.mud/config"
    *disabled*)
      TEST_FAILURE_REASON="Output missing 'disabled': $output"
  # Verify setting was removed
  if grep -q "^cd-look=1$" "$tmpdir/.spellbook/.mud/config"; then
    TEST_FAILURE_REASON="cd-look=1 still in config after disable"
  # Verify other settings preserved
  if ! grep -q "^other-setting=1$" "$tmpdir/.spellbook/.mud/config"; then
    TEST_FAILURE_REASON="other settings were not preserved"
run_test_case "toggle-cd is executable" test_toggle_cd_is_executable
run_test_case "toggle-cd --help shows usage" test_toggle_cd_help_shows_usage
run_test_case "toggle-cd enables when disabled" test_toggle_cd_enables_when_disabled
run_test_case "toggle-cd disables when enabled" test_toggle_cd_disables_when_enabled
finish_tests
