#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - system-menu requires the menu dependency
# - system-menu forwards system actions to the menu

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
kill -TERM "$PPID" 2>/dev/null || exit 0; exit 0
SH
  chmod +x "$tmp/menu"
}

make_stub_require() {
  tmp=$1
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s %s\n' "$1" "$2" >>"$REQUIRE_LOG"
exit 0
SH
  chmod +x "$tmp/require-command"
}

test_system_menu_checks_requirements() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" REQUIRE_LOG="$tmp/req" "$ROOT_DIR/spells/menu/system-menu"
  _assert_success && _assert_path_exists "$tmp/req"
}

test_system_menu_includes_test_utilities() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/system-menu"
  _assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"System Menu:"*"Restart...%shutdown-menu"*"Update all software%update-all -v"*"Update wizardry%update-wizardry"*"Manage services%"*"services-menu"*"Test all wizardry spells%test-magic"*'Exit%kill -TERM $PPID' ) : ;;
    *) TEST_FAILURE_REASON="expected system actions missing: $args"; return 1 ;;
  esac
}

_run_test_case "system-menu requires menu dependency" test_system_menu_checks_requirements
_run_test_case "system-menu passes system actions to menu" test_system_menu_includes_test_utilities

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/system-menu"
  _assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *'Exit%kill -TERM $PPID') : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
}

_run_test_case "system-menu ESC/Exit behavior" test_esc_exit_behavior

test_shows_help() {
  _run_cmd "$ROOT_DIR/spells/menu/system-menu" --help
  _assert_success
  _assert_output_contains "Usage: system-menu"
}

_run_test_case "system-menu --help shows usage" test_shows_help

# Test that no exit message is printed when ESC or Exit is used
test_no_exit_message_on_esc() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/system-menu"
  _assert_success || return 1
  
  # Verify no "Exiting" message appears in stderr
  case "$ERROR" in
    *"Exiting"*) 
      TEST_FAILURE_REASON="should not print exit message, got: $ERROR"
      return 1
      ;;
  esac
  return 0
}

_run_test_case "system-menu no exit message on ESC" test_no_exit_message_on_esc

# Test that exactly one blank line appears when selecting menu items
test_single_blank_line_on_selection() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  
  # Create a stub service menu
  cat >"$tmp/services-menu" <<'SH'
#!/bin/sh
printf 'Services menu displayed\n'
exit 0
SH
  chmod +x "$tmp/services-menu"
  
  # Create a menu that simulates real behavior
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$1" >>"$MENU_OUTPUT"
shift
printf '%s\n' "$1" >>"$MENU_OUTPUT"
# Single blank line before executing command
printf '\n' >>"$MENU_OUTPUT"
# Execute the services-menu command
services-menu >>"$MENU_OUTPUT" 2>&1
kill -TERM "$PPID" 2>/dev/null || exit 0
exit 0
SH
  chmod +x "$tmp/menu"
  
  make_stub_require "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  MENU_OUTPUT="$tmp/output"
  _run_cmd env PATH="$tmp:$PATH" MENU_OUTPUT="$MENU_OUTPUT" "$ROOT_DIR/spells/menu/system-menu"
  _assert_success || return 1
  
  if [ -f "$MENU_OUTPUT" ]; then
    blank_count=$(grep -c '^$' "$MENU_OUTPUT" || true)
    if [ "$blank_count" -ne 1 ]; then
      TEST_FAILURE_REASON="Expected exactly 1 blank line, got $blank_count"
      return 1
    fi
  fi
  
  return 0
}

_run_test_case "system-menu shows exactly one blank line on selection" test_single_blank_line_on_selection


# Test via source-then-invoke pattern  
system_menu_help_via_sourcing() {
  _run_sourced_spell system-menu --help
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

_run_test_case "system-menu works via source-then-invoke" system_menu_help_via_sourcing
_finish_tests
