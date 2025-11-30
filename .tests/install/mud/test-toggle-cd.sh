#!/bin/sh
# Tests for toggle-cd spell
# Behavioral cases:
# - toggle-cd installs the hook when not present
# - toggle-cd uninstalls the hook when present
# - toggle-cd --help shows usage

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_toggle_cd_is_executable() {
  [ -x "$ROOT_DIR/spells/install/mud/toggle-cd" ]
}

test_toggle_cd_requires_cd_spell() {
  content=$(cat "$ROOT_DIR/spells/install/mud/toggle-cd")
  case "$content" in
    *CD_SPELL*cd*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="toggle-cd should reference the cd spell"
      return 1
      ;;
  esac
}

test_toggle_cd_has_install_and_uninstall() {
  content=$(cat "$ROOT_DIR/spells/install/mud/toggle-cd")
  case "$content" in
    *install*uninstall*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="toggle-cd should handle both install and uninstall"
      return 1
      ;;
  esac
}

test_toggle_cd_installs_when_not_present() {
  tmp=$(make_tempdir)
  # Create an empty rc file without the hook
  : >"$tmp/rc"
  
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/toggle-cd"
  assert_success || return 1
  assert_output_contains "CD hook enabled" || return 1
  
  # Verify hook was installed
  if ! grep -q ">>> wizardry cd cantrip >>>" "$tmp/rc"; then
    TEST_FAILURE_REASON="Hook not installed after toggle"
    return 1
  fi
}

test_toggle_cd_uninstalls_when_present() {
  tmp=$(make_tempdir)
  
  # First install the hook
  run_cmd env WIZARDRY_CD_CANTRIP="$ROOT_DIR/spells/install/mud/cd" WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/cd" install
  assert_success || return 1
  
  # Now toggle should uninstall it
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/toggle-cd"
  assert_success || return 1
  assert_output_contains "CD hook disabled" || return 1
  
  # Verify hook was removed
  if grep -q ">>> wizardry cd cantrip >>>" "$tmp/rc"; then
    TEST_FAILURE_REASON="Hook still present after toggle off"
    return 1
  fi
}

test_toggle_cd_help_shows_usage() {
  run_spell spells/install/mud/toggle-cd --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "toggle" || return 1
}

run_test_case "toggle-cd is executable" test_toggle_cd_is_executable
run_test_case "toggle-cd requires cd spell" test_toggle_cd_requires_cd_spell
run_test_case "toggle-cd handles install and uninstall" test_toggle_cd_has_install_and_uninstall
run_test_case "toggle-cd installs when not present" test_toggle_cd_installs_when_not_present
run_test_case "toggle-cd uninstalls when present" test_toggle_cd_uninstalls_when_present
run_test_case "toggle-cd --help shows usage" test_toggle_cd_help_shows_usage
finish_tests
