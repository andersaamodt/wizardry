#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - mud-admin shows usage with --help
# - mud-admin presents admin actions to menu
# - mud-admin exits on interrupt triggered by menu stub

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
printf 'oops\n' >&2
exit 7
SH
  chmod +x "$tmp/menu"
}

test_mud_admin_calls_menu_with_actions() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
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
  _run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-admin-menu"
  _assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"MUD Admin:"*"Add authorized player%add-player"*"List authorized players%new-player"*"List shared rooms%list-rooms"*'Exit%kill -TERM $PPID' ) : ;;
    *) TEST_FAILURE_REASON="menu not invoked with expected actions: $args"; return 1 ;;
  esac
}

test_mud_admin_requires_menu_helper() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_colors "$tmp"
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s\n' "The MUD Admin menu needs the 'menu' command to present options." >&2
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
  _run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$ROOT_DIR/spells/cantrips:$tmp:/bin:/usr/bin" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/mud-admin-menu"
  _assert_failure
  _assert_error_contains "The MUD Admin menu needs the 'menu' command"
}

test_mud_admin_reports_menu_failure() {
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
  _run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-admin-menu"
  _assert_status 7
  _assert_file_contains "$tmp/log" "MUD Admin:"
}

test_shows_help() {
  _run_spell "spells/menu/mud-admin-menu" --help
  _assert_success || return 1
  _assert_error_contains "Usage:" || return 1
}

_run_test_case "mud-admin shows usage" test_shows_help
_run_test_case "mud-admin presents admin actions" test_mud_admin_calls_menu_with_actions
_run_test_case "mud-admin fails fast when menu helper is missing" test_mud_admin_requires_menu_helper
_run_test_case "mud-admin surfaces menu failures" test_mud_admin_reports_menu_failure

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
  
  
  _run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/mud-admin-menu"
  _assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *'Exit%kill -TERM $PPID') : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
  
}

_run_test_case "mud-admin ESC/Exit behavior" test_esc_exit_behavior

_finish_tests
