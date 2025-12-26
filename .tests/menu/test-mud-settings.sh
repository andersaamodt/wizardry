#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - mud-settings shows usage with --help
# - mud-settings presents player management and install actions
# - mud-settings exits when interrupted by menu stub

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
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
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
  # Note: Without a player key, menu shows "Create player key" instead of "Copy player key"
  _run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MUD_PLAYER="$player" MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-settings"
  _assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"MUD Settings:"*"player key"*"Change Player%select-player"*"New Player%new-player"*'Exit%kill -TERM $PPID' ) : ;;
    *) TEST_FAILURE_REASON="mud settings actions missing: $args"; return 1 ;;
  esac
}

test_mud_settings_requires_menu_helper() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_colors "$tmp"
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s\n' "The MUD Settings menu needs the 'menu' command to present options." >&2
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
  _run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$tmp:/bin:/usr/bin" MENU_LOG="$tmp/log" MUD_PLAYER=hero "$ROOT_DIR/spells/menu/mud-settings"
  _assert_failure
  _assert_error_contains "The MUD Settings menu needs the 'menu' command"
}

test_mud_settings_reports_menu_failure() {
  tmp=$(_make_tempdir)
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
  _run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MUD_PLAYER=hero MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-settings"
  _assert_status 9
  _assert_file_contains "$tmp/log" "MUD Settings:"
}

test_shows_help() {
  _run_spell "spells/menu/mud-settings" --help
  _assert_success || return 1
  _assert_error_contains "Usage:" || return 1
}

_run_test_case "mud-settings shows usage" test_shows_help
_run_test_case "mud-settings presents player actions" test_mud_settings_menu_actions
_run_test_case "mud-settings fails fast when menu helper is missing" test_mud_settings_requires_menu_helper
_run_test_case "mud-settings surfaces menu failures" test_mud_settings_reports_menu_failure

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  tmp=$(_make_tempdir)
  make_stub_colors "$tmp"
  
  # Create menu stub that returns escape status
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
kill -TERM "$PPID" 2>/dev/null || exit 0; exit 0
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
  
  
  _run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MUD_PLAYER=hero "$ROOT_DIR/spells/menu/mud-settings"
  _assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *'Exit%kill -TERM $PPID') : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
  
}

_run_test_case "mud-settings ESC/Exit behavior" test_esc_exit_behavior


# Test via source-then-invoke pattern  
mud_settings_help_via_sourcing() {
  _run_sourced_spell mud-settings --help
  _assert_success || return 1
  # Help text may go to stdout or stderr depending on spell
  if [ -n "$OUTPUT" ]; then
    case "$OUTPUT" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  if [ -n "$ERROR" ]; then
    case "$ERROR" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  TEST_FAILURE_REASON="expected 'Usage:' in output or error"
  return 1
}

_run_test_case "mud-settings works via source-then-invoke" mud_settings_help_via_sourcing
_finish_tests
