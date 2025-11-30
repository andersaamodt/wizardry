#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - mud-install-menu offers tor setup and exits on interrupt
# - mud-install-menu shows CD hook toggle with [X]/[ ] status

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

make_stub_menu() {
  tmp=$1
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
kill -s INT "$PPID"
exit 0
SH
  chmod +x "$tmp/menu"
}

make_stub_colors() {
  tmp=$1
  cat >"$tmp/colors" <<'SH'
#!/bin/sh
RESET=''
CYAN=''
GREY=''
SH
  chmod +x "$tmp/colors"
}

make_failing_menu() {
  tmp=$1
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
printf 'menu busted\n' >&2
exit 5
SH
  chmod +x "$tmp/menu"
}

test_mud_install_menu_calls_tor_installer() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_colors "$tmp"
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
command -v "$1" >/dev/null 2>&1
SH
  chmod +x "$tmp/require-command"
  # Stub exit-label to return "Back" for submenu behavior
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  # Test as submenu (as it would be called from mud menu)
  # Use MENU_LOOP_LIMIT=1 to exit after one iteration
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-install-menu"
  assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"MUD Install:"*"/install/tor/setup-tor"*"Exit%exit 113"* ) : ;;
    *) TEST_FAILURE_REASON="tor setup entry missing: $args"; return 1 ;;
  esac
}

test_mud_install_menu_requires_menu_helper() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s\n' "The MUD Install menu needs the 'menu' command to present options." >&2
exit 1
SH
  chmod +x "$tmp/require-command"
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/mud-install-menu"
  assert_failure
  assert_error_contains "The MUD Install menu needs the 'menu' command"
}

test_mud_install_menu_reports_menu_failure() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  make_failing_menu "$tmp"
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
command -v "$1" >/dev/null 2>&1
SH
  chmod +x "$tmp/require-command"
  # Stub exit-label
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-install-menu"
  assert_status 5
  assert_file_contains "$tmp/log" "MUD Install:"
}

run_test_case "mud-install-menu invokes tor setup" test_mud_install_menu_calls_tor_installer
run_test_case "mud-install-menu fails fast when menu helper is missing" test_mud_install_menu_requires_menu_helper
run_test_case "mud-install-menu surfaces menu failures" test_mud_install_menu_reports_menu_failure

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  
  # Create menu stub that returns escape status
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit 113
SH
  chmod +x "$tmp/menu"
  
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/require-command"
  
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/mud-install-menu"
  assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *"Exit%exit 113"*) : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
  
}

run_test_case "mud-install-menu ESC/Exit behavior" test_esc_exit_behavior

# Test CD hook toggle shows [ ] when not installed
test_cd_hook_toggle_unchecked() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  
  # Create menu stub that logs and exits
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit 113
SH
  chmod +x "$tmp/menu"
  
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/require-command"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Use a temp rc file that doesn't have the cd hook installed
  rc_file="$tmp/rc"
  : >"$rc_file"
  
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" WIZARDRY_RC_FILE="$rc_file" "$ROOT_DIR/spells/menu/mud-install-menu"
  assert_success || return 1
  
  args=$(cat "$tmp/log")
  case "$args" in
    *"[ ] CD hook"*) : ;;
    *) TEST_FAILURE_REASON="CD hook should show [ ] when not installed: $args"; return 1 ;;
  esac
}

# Test CD hook toggle shows [X] when installed
test_cd_hook_toggle_checked() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  
  # Create menu stub that logs and exits
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit 113
SH
  chmod +x "$tmp/menu"
  
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/require-command"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Use a temp rc file with the cd hook marker installed
  rc_file="$tmp/rc"
  cat >"$rc_file" <<'RC'
# >>> wizardry cd cantrip >>>
WIZARDRY_CD_CANTRIP='/path/to/cd'
alias cd='. "$WIZARDRY_CD_CANTRIP"'
# <<< wizardry cd cantrip <<<
RC
  
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" WIZARDRY_RC_FILE="$rc_file" "$ROOT_DIR/spells/menu/mud-install-menu"
  assert_success || return 1
  
  args=$(cat "$tmp/log")
  case "$args" in
    *"[X] CD hook"*) : ;;
    *) TEST_FAILURE_REASON="CD hook should show [X] when installed: $args"; return 1 ;;
  esac
}

# Test --help shows usage
test_mud_install_menu_help() {
  run_cmd "$ROOT_DIR/spells/menu/mud-install-menu" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "CD hook" || return 1
}

run_test_case "CD hook toggle shows [ ] when not installed" test_cd_hook_toggle_unchecked
run_test_case "CD hook toggle shows [X] when installed" test_cd_hook_toggle_checked
run_test_case "mud-install-menu --help shows usage" test_mud_install_menu_help

# Test new MUD feature toggles
test_command_not_found_toggle_unchecked() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  
  # Create menu stub that logs and exits
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit 113
SH
  chmod +x "$tmp/menu"
  
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/require-command"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Use a temp rc file and config dir with no features enabled
  rc_file="$tmp/rc"
  : >"$rc_file"
  config_dir="$tmp/mud"
  mkdir -p "$config_dir"
  
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" WIZARDRY_RC_FILE="$rc_file" WIZARDRY_MUD_CONFIG_DIR="$config_dir" "$ROOT_DIR/spells/menu/mud-install-menu"
  assert_success || return 1
  
  args=$(cat "$tmp/log")
  case "$args" in
    *"[ ] Command not found hook"*) : ;;
    *) TEST_FAILURE_REASON="Command not found hook should show [ ] when not enabled: $args"; return 1 ;;
  esac
}

test_command_not_found_toggle_checked() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit 113
SH
  chmod +x "$tmp/menu"
  
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/require-command"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Use a temp rc file and config dir with feature enabled
  rc_file="$tmp/rc"
  : >"$rc_file"
  config_dir="$tmp/mud"
  mkdir -p "$config_dir"
  printf '%s\n' "command-not-found=1" >"$config_dir/config"
  
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" WIZARDRY_RC_FILE="$rc_file" WIZARDRY_MUD_CONFIG_DIR="$config_dir" "$ROOT_DIR/spells/menu/mud-install-menu"
  assert_success || return 1
  
  args=$(cat "$tmp/log")
  case "$args" in
    *"[X] Command not found hook"*) : ;;
    *) TEST_FAILURE_REASON="Command not found hook should show [X] when enabled: $args"; return 1 ;;
  esac
}

test_all_features_toggle_shown() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit 113
SH
  chmod +x "$tmp/menu"
  
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/require-command"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  rc_file="$tmp/rc"
  : >"$rc_file"
  config_dir="$tmp/mud"
  mkdir -p "$config_dir"
  
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" WIZARDRY_RC_FILE="$rc_file" WIZARDRY_MUD_CONFIG_DIR="$config_dir" "$ROOT_DIR/spells/menu/mud-install-menu"
  assert_success || return 1
  
  args=$(cat "$tmp/log")
  # Should show "Enable all MUD features" item
  case "$args" in
    *"Enable all MUD features"*) : ;;
    *) TEST_FAILURE_REASON="Menu should show 'Enable all MUD features' toggle: $args"; return 1 ;;
  esac
}

test_all_planned_features_shown() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit 113
SH
  chmod +x "$tmp/menu"
  
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/require-command"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  rc_file="$tmp/rc"
  : >"$rc_file"
  config_dir="$tmp/mud"
  mkdir -p "$config_dir"
  
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" WIZARDRY_RC_FILE="$rc_file" WIZARDRY_MUD_CONFIG_DIR="$config_dir" "$ROOT_DIR/spells/menu/mud-install-menu"
  assert_success || return 1
  
  args=$(cat "$tmp/log")
  # Check all planned features are shown
  case "$args" in
    *"Touch hook"*) : ;;
    *) TEST_FAILURE_REASON="Menu should show Touch hook: $args"; return 1 ;;
  esac
  case "$args" in
    *"Fantasy theme"*) : ;;
    *) TEST_FAILURE_REASON="Menu should show Fantasy theme: $args"; return 1 ;;
  esac
  case "$args" in
    *"Inventory feature"*) : ;;
    *) TEST_FAILURE_REASON="Menu should show Inventory feature: $args"; return 1 ;;
  esac
  case "$args" in
    *"HP/MP and combat"*) : ;;
    *) TEST_FAILURE_REASON="Menu should show HP/MP and combat: $args"; return 1 ;;
  esac
}

run_test_case "Command not found toggle shows [ ] when disabled" test_command_not_found_toggle_unchecked
run_test_case "Command not found toggle shows [X] when enabled" test_command_not_found_toggle_checked
run_test_case "Enable all MUD features toggle shown" test_all_features_toggle_shown
run_test_case "All planned MUD features shown" test_all_planned_features_shown

finish_tests
