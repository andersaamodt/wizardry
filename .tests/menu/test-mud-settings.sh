#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - mud-settings presents player management and install actions
# - mud-settings exits when interrupted by menu stub

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
printf 'failure\n' >&2
exit 9
SH
  chmod +x "$tmp/menu"
}

test_mud_settings_menu_actions() {
  tmp=$(make_tempdir)
  player=hero
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
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MUD_PLAYER="$player" MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-settings"
  assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"MUD Settings:"*"Copy player key to clipboard%copy ~/.ssh/"*"Change Player%select-player"*"New Player%new-player"*"Install%launch_submenu mud-menu"*"Exit%exit 113"* ) : ;;
    *) TEST_FAILURE_REASON="mud settings actions missing: $args"; return 1 ;;
  esac
}

test_mud_settings_requires_menu_helper() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s\n' "The MUD Settings menu needs the 'menu' command to present options." >&2
exit 1
SH
  chmod +x "$tmp/require-command"
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp" MENU_LOG="$tmp/log" MUD_PLAYER=hero "$ROOT_DIR/spells/menu/mud-settings"
  assert_failure
  assert_error_contains "The MUD Settings menu needs the 'menu' command"
}

test_mud_settings_reports_menu_failure() {
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
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MUD_PLAYER=hero MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-settings"
  assert_status 9
  assert_file_contains "$tmp/log" "MUD Settings:"
}

run_test_case "mud-settings presents player actions" test_mud_settings_menu_actions
run_test_case "mud-settings fails fast when menu helper is missing" test_mud_settings_requires_menu_helper
run_test_case "mud-settings surfaces menu failures" test_mud_settings_reports_menu_failure

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
  
  
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MUD_PLAYER=hero "$ROOT_DIR/spells/menu/mud-settings"
  assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *"Exit%exit 113"*) : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
  
}

run_test_case "mud-settings ESC/Exit behavior" test_esc_exit_behavior

finish_tests
