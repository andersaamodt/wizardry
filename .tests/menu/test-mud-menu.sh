#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - mud-menu offers tor setup and exits on interrupt
# - mud-menu shows cd hook toggle with [X]/[ ] status

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

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

make_stub_check_cd_hook() {
  tmp=$1
  cat >"$tmp/check-cd-hook" <<'SH'
#!/bin/sh
# Stub for check-cd-hook - MUST check only WIZARDRY_RC_FILE
# This stub is designed to be found first in PATH via $tmp
set -eu
rc_file=${WIZARDRY_RC_FILE-}
if [ -z "$rc_file" ]; then
  # If WIZARDRY_RC_FILE not set, hook is NOT installed
  exit 1
fi
# Only check the specified file, never fall back to user's RC files
if [ ! -f "$rc_file" ]; then
  # File doesn't exist, hook is NOT installed
  exit 1
fi
# Check for the marker in the specified file
if grep -Fq '# >>> wizardry cd cantrip >>>' "$rc_file" 2>/dev/null; then
  exit 0
fi
# Marker not found, hook is NOT installed
exit 1
SH
  chmod +x "$tmp/check-cd-hook"
}

make_stub_mud_config() {
  tmp=$1
  cat >"$tmp/mud-config" <<'SH'
#!/bin/sh
# Stub for mud-config - returns 0 for all features (disabled state)
set -eu
if [ "$1" = "get" ]; then
  # Return 0 for disabled (so menu shows [ ] checkboxes)
  printf '0\n'
  exit 0
fi
exit 1
SH
  chmod +x "$tmp/mud-config"
}

make_stub_check_command_not_found_hook() {
  tmp=$1
  cat >"$tmp/check-command-not-found-hook" <<'SH'
#!/bin/sh
# Stub for check-command-not-found-hook - always returns 1 (not installed)
exit 1
SH
  chmod +x "$tmp/check-command-not-found-hook"
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
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-menu"
  assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"MUD Install:"*"setup-tor"*'Exit%exit 130' ) : ;;
    *) TEST_FAILURE_REASON="tor setup entry missing: $args"; return 1 ;;
  esac
}

test_mud_install_menu_requires_menu_helper() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s\n' "The MUD Install menu needs the 'menu' command to present options." >&2
exit 1
SH
  chmod +x "$tmp/require-command"
  # Create stub require that honors REQUIRE_COMMAND (like the real imp)
  cat >"$tmp/require" <<'SH'
#!/bin/sh
if [ -n "${REQUIRE_COMMAND-}" ]; then
  "$REQUIRE_COMMAND" "$@"
else
  require-command "$@"
fi
SH
  chmod +x "$tmp/require"
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$tmp:/bin:/usr/bin" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/mud-menu"
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
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-menu"
  assert_status 5
  assert_file_contains "$tmp/log" "MUD Install:"
}

run_test_case "mud-menu invokes tor setup" test_mud_install_menu_calls_tor_installer
run_test_case "mud-menu fails fast when menu helper is missing" test_mud_install_menu_requires_menu_helper
run_test_case "mud-menu surfaces menu failures" test_mud_install_menu_reports_menu_failure

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  
  # Create menu stub that returns escape status
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit 130
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
  
  
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/mud-menu"
  assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *'Exit%exit 130') : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
  
}

run_test_case "mud-menu ESC/Exit behavior" test_esc_exit_behavior

# Test cd hook toggle shows [ ] when not installed
test_cd_hook_toggle_unchecked() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  
  # Create menu stub that logs and exits
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit 130
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
  
  make_stub_check_cd_hook "$tmp"
  
  # Use a temp rc file that doesn't have the cd hook installed
  rc_file="$tmp/rc"
  : >"$rc_file"
  
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$WIZARDRY_IMPS_PATH:$tmp:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" MENU_LOG="$tmp/log" WIZARDRY_RC_FILE="$rc_file" "$ROOT_DIR/spells/menu/mud-menu"
  assert_success || return 1
  
  args=$(cat "$tmp/log")
  case "$args" in
    *"[ ] cd hook"*) : ;;
    *) TEST_FAILURE_REASON="cd hook should show [ ] when not installed: $args"; return 1 ;;
  esac
}

# Test cd hook toggle shows [X] when installed
test_cd_hook_toggle_checked() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  
  # Create menu stub that logs and exits
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit 130
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
  
  make_stub_check_cd_hook "$tmp"
  
  # Use a temp rc file with the cd hook marker installed (new format uses function)
  rc_file="$tmp/rc"
  cat >"$rc_file" <<'RC'
# >>> wizardry cd cantrip >>>
cd() { command cd "$@" && { look 2>/dev/null || true; }; }
# <<< wizardry cd cantrip <<<
RC
  
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$WIZARDRY_IMPS_PATH:$tmp:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" MENU_LOG="$tmp/log" WIZARDRY_RC_FILE="$rc_file" "$ROOT_DIR/spells/menu/mud-menu"
  assert_success || return 1
  
  args=$(cat "$tmp/log")
  case "$args" in
    *"[X] cd hook"*) : ;;
    *) TEST_FAILURE_REASON="cd hook should show [X] when installed: $args"; return 1 ;;
  esac
}

# Test --help shows usage
test_mud_install_menu_help() {
  run_cmd "$ROOT_DIR/spells/menu/mud-menu" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "cd hook" || return 1
}

run_test_case "cd hook toggle shows [ ] when not installed" test_cd_hook_toggle_unchecked
run_test_case "cd hook toggle shows [X] when installed" test_cd_hook_toggle_checked
run_test_case "mud-menu --help shows usage" test_mud_install_menu_help

test_all_features_toggle_shown() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit 130
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
  
  make_stub_check_cd_hook "$tmp"
  make_stub_mud_config "$tmp"
  make_stub_check_command_not_found_hook "$tmp"
  
  rc_file="$tmp/rc"
  : >"$rc_file"
  config_dir="$tmp/mud"
  mkdir -p "$config_dir"
  
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$WIZARDRY_IMPS_PATH:$tmp:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" MENU_LOG="$tmp/log" MUD_DIR="$config_dir" "$ROOT_DIR/spells/menu/mud-menu"
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
exit 130
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
  
  make_stub_check_cd_hook "$tmp"
  make_stub_mud_config "$tmp"
  make_stub_check_command_not_found_hook "$tmp"
  
  rc_file="$tmp/rc"
  : >"$rc_file"
  config_dir="$tmp/mud"
  mkdir -p "$config_dir"
  
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$WIZARDRY_IMPS_PATH:$tmp:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" MENU_LOG="$tmp/log" MUD_DIR="$config_dir" "$ROOT_DIR/spells/menu/mud-menu"
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

run_test_case "Enable all MUD features toggle shown" test_all_features_toggle_shown
run_test_case "All planned MUD features shown" test_all_planned_features_shown

# Test that toggle selection keeps cursor position
test_toggle_keeps_cursor_position_cd_hook() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  
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
  
  make_stub_check_cd_hook "$tmp"
  make_stub_mud_config "$tmp"
  make_stub_check_command_not_found_hook "$tmp"
  
  # Create a menu stub that logs --start-selection argument and simulates toggle action
  call_count_file="$tmp/call_count"
  printf '0\n' >"$call_count_file"
  
  # Use a temp rc file that doesn't have the cd hook installed
  rc_file="$tmp/rc"
  : >"$rc_file"
  config_dir="$tmp/mud"
  mkdir -p "$config_dir"
  
  # Menu stub that simulates CD hook toggle by directly modifying the rc file
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
call_count=$(cat "$CALL_COUNT_FILE")
# Parse --start-selection argument
start_sel=1
while [ "$#" -gt 0 ]; do
  case $1 in
    --start-selection)
      start_sel=$2
      shift 2
      ;;
    *)
      break
      ;;
  esac
done
printf '%s\n' "START_SELECTION=$start_sel" >>"$MENU_LOG"
call_count=$((call_count + 1))
printf '%s\n' "$call_count" >"$CALL_COUNT_FILE"
if [ "$call_count" -eq 1 ]; then
  # First call: simulate CD hook toggle by directly modifying rc file
  rc_file=${WIZARDRY_RC_FILE:-$HOME/.bashrc}
  printf '%s\n' '# >>> wizardry cd cantrip >>>' >> "$rc_file"
  printf '%s\n' 'cd() { command cd "$@" && { look 2>/dev/null || true; }; }' >> "$rc_file"
  printf '%s\n' '# <<< wizardry cd cantrip <<<' >> "$rc_file"
  exit 0
fi
# Second call: exit
exit 130
SH
  chmod +x "$tmp/menu"
  
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$WIZARDRY_IMPS_PATH:$tmp:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" MENU_LOG="$tmp/log" CALL_COUNT_FILE="$call_count_file" MUD_DIR="$config_dir" WIZARDRY_RC_FILE="$rc_file" "$ROOT_DIR/spells/menu/mud-menu"
  assert_success || { TEST_FAILURE_REASON="menu should exit successfully"; return 1; }
  
  log_content=$(cat "$tmp/log")
  # First call should have start_selection=1
  # Second call (after toggle) should have start_selection=3 (stayed on CD hook item which is position 3)
  first_selection=$(printf '%s\n' "$log_content" | head -1 | sed 's/.*START_SELECTION=//')
  second_selection=$(printf '%s\n' "$log_content" | sed -n '2p' | sed 's/.*START_SELECTION=//')
  
  if [ "$first_selection" != "1" ]; then
    TEST_FAILURE_REASON="first menu call should have start_selection=1, got $first_selection"
    return 1
  fi
  
  if [ "$second_selection" != "3" ]; then
    TEST_FAILURE_REASON="after CD hook toggle, menu should have start_selection=3 (CD hook position), got $second_selection (log: $log_content)"
    return 1
  fi
}

# Test that command-not-found toggle keeps cursor at position 2
# Test that non-toggle action resets cursor to first item
test_non_toggle_resets_cursor() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  
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
  
  make_stub_check_cd_hook "$tmp"
  make_stub_mud_config "$tmp"
  make_stub_check_command_not_found_hook "$tmp"
  
  call_count_file="$tmp/call_count"
  printf '0\n' >"$call_count_file"
  
  rc_file="$tmp/rc"
  : >"$rc_file"
  config_dir="$tmp/mud"
  mkdir -p "$config_dir"
  
  # Menu stub that just exits 0 on first call (simulating non-state-changing action)
  # and exits 113 on second call
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
call_count=$(cat "$CALL_COUNT_FILE")
start_sel=1
while [ "$#" -gt 0 ]; do
  case $1 in
    --start-selection)
      start_sel=$2
      shift 2
      ;;
    *)
      break
      ;;
  esac
done
printf '%s\n' "START_SELECTION=$start_sel" >>"$MENU_LOG"
call_count=$((call_count + 1))
printf '%s\n' "$call_count" >"$CALL_COUNT_FILE"
if [ "$call_count" -eq 1 ]; then
  # First call: return success without changing any state
  exit 0
fi
exit 130
SH
  chmod +x "$tmp/menu"
  
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$WIZARDRY_IMPS_PATH:$tmp:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" MENU_LOG="$tmp/log" CALL_COUNT_FILE="$call_count_file" MUD_DIR="$config_dir" WIZARDRY_RC_FILE="$rc_file" "$ROOT_DIR/spells/menu/mud-menu"
  assert_success || { TEST_FAILURE_REASON="menu should exit successfully"; return 1; }
  
  log_content=$(cat "$tmp/log")
  first_selection=$(printf '%s\n' "$log_content" | head -1 | sed 's/.*START_SELECTION=//')
  second_selection=$(printf '%s\n' "$log_content" | sed -n '2p' | sed 's/.*START_SELECTION=//')
  
  if [ "$first_selection" != "1" ]; then
    TEST_FAILURE_REASON="first menu call should have start_selection=1, got $first_selection"
    return 1
  fi
  
  if [ "$second_selection" != "1" ]; then
    TEST_FAILURE_REASON="after non-toggle action, menu should have start_selection=1, got $second_selection (log: $log_content)"
    return 1
  fi
}

run_test_case "mud-menu cd hook toggle keeps cursor position" test_toggle_keeps_cursor_position_cd_hook
run_test_case "mud-menu non-toggle resets cursor" test_non_toggle_resets_cursor


# Test via source-then-invoke pattern  

finish_tests
