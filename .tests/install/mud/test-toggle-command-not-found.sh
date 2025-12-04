#!/bin/sh
# Tests for toggle-command-not-found - Toggle command not found hook on/off
# Behavioral cases:
# - toggle-command-not-found installs the hook when not present
# - toggle-command-not-found uninstalls the hook when present
# - toggle-command-not-found --help shows usage

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_toggle_cnf_is_executable() {
  [ -x "$ROOT_DIR/spells/install/mud/toggle-command-not-found" ]
}

test_toggle_cnf_requires_cnf_spell() {
  content=$(cat "$ROOT_DIR/spells/install/mud/toggle-command-not-found")
  case "$content" in
    *CNF_SPELL*handle-command-not-found*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="toggle-command-not-found should reference the handle-command-not-found spell"
      return 1
      ;;
  esac
}

test_toggle_cnf_has_install_and_uninstall() {
  content=$(cat "$ROOT_DIR/spells/install/mud/toggle-command-not-found")
  case "$content" in
    *install*uninstall*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="toggle-command-not-found should handle both install and uninstall"
      return 1
      ;;
  esac
}

test_help_shows_usage() {
  run_spell "spells/install/mud/toggle-command-not-found" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "command-not-found" || return 1
}

test_toggle_installs_when_not_present() {
  tmp=$(make_tempdir)
  # Create an empty rc file without the hook
  : >"$tmp/rc"
  
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/toggle-command-not-found"
  assert_success || return 1
  assert_output_contains "enabled" || return 1
  
  # Verify hook was installed
  if ! grep -q ">>> wizardry command-not-found >>>" "$tmp/rc"; then
    TEST_FAILURE_REASON="Hook not installed after toggle"
    return 1
  fi
}

test_toggle_uninstalls_when_present() {
  tmp=$(make_tempdir)
  
  # First install the hook
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/handle-command-not-found" install
  assert_success || return 1
  
  # Now toggle should uninstall it
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/toggle-command-not-found"
  assert_success || return 1
  assert_output_contains "disabled" || return 1
  
  # Verify hook was removed
  if grep -q ">>> wizardry command-not-found >>>" "$tmp/rc"; then
    TEST_FAILURE_REASON="Hook still present after toggle off"
    return 1
  fi
}

test_toggle_shows_installing_message() {
  tmp=$(make_tempdir)
  # Create an empty rc file without the hook
  : >"$tmp/rc"
  
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/toggle-command-not-found"
  assert_success || return 1
  # Verify it shows the progress message before install
  assert_output_contains "Installing command-not-found hook" || return 1
}

test_toggle_shows_uninstalling_message() {
  tmp=$(make_tempdir)
  
  # First install the hook
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/handle-command-not-found" install
  assert_success || return 1
  
  # Now toggle should uninstall it and show a progress message
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/toggle-command-not-found"
  assert_success || return 1
  # Verify it shows the progress message before uninstall
  assert_output_contains "Uninstalling command-not-found hook" || return 1
}

test_fails_when_cnf_spell_missing() {
  tmp=$(make_tempdir)
  # Copy the toggle script to a temp location without handle-command-not-found
  cp "$ROOT_DIR/spells/install/mud/toggle-command-not-found" "$tmp/toggle-command-not-found"
  chmod +x "$tmp/toggle-command-not-found"
  
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$tmp/toggle-command-not-found"
  assert_failure || return 1
  assert_error_contains "handle-command-not-found spell not found" || return 1
}

run_test_case "toggle-command-not-found is executable" test_toggle_cnf_is_executable
run_test_case "toggle-command-not-found requires handle-command-not-found spell" test_toggle_cnf_requires_cnf_spell
run_test_case "toggle-command-not-found handles install and uninstall" test_toggle_cnf_has_install_and_uninstall
run_test_case "toggle-command-not-found --help shows usage" test_help_shows_usage
run_test_case "toggle-command-not-found installs when not present" test_toggle_installs_when_not_present
run_test_case "toggle-command-not-found uninstalls when present" test_toggle_uninstalls_when_present
run_test_case "toggle-command-not-found shows installing message" test_toggle_shows_installing_message
run_test_case "toggle-command-not-found shows uninstalling message" test_toggle_shows_uninstalling_message
run_test_case "toggle-command-not-found fails when handle-command-not-found missing" test_fails_when_cnf_spell_missing

finish_tests
