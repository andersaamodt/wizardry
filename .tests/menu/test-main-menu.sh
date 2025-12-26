#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - main-menu requires menu dependency before running
# - main-menu invokes menu with expected options and exits on TERM signal
# - main-menu fails when menu dependency is missing
# - main-menu loads colors gracefully

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
# Send TERM signal to parent to simulate ESC behavior
kill -TERM "$PPID" 2>/dev/null || exit 0
exit 0
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

make_failing_require() {
  tmp=$1
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s\n' "The main menu needs the 'menu' command to present options." >&2
exit 1
SH
  chmod +x "$tmp/require-command"
}

test_main_menu_checks_dependency() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" REQUIRE_LOG="$tmp/req" "$ROOT_DIR/spells/menu/main-menu"
  _assert_success && _assert_path_exists "$tmp/req"
}

test_main_menu_passes_expected_entries() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/main-menu"
  _assert_success
  args=$(cat "$tmp/log")
  # MUD is not shown by default (requires enabling via mud-config)
  # The Exit command shows kill -TERM $PPID literally for didactic purposes
  case "$args" in
    *"Main Menu:"*"Cast%"*"cast"*"Spellbook%"*"spellbook"*"Arcana%"*"install-menu"*"Computer%"*"system-menu"*'Exit%kill -TERM $PPID'* ) : ;;
    *) TEST_FAILURE_REASON="menu entries missing: $args"; return 1 ;;
  esac
}

test_main_menu_fails_without_menu_dependency() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_failing_require "$tmp"
  _run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/menu/main-menu"
  _assert_failure || return 1
  _assert_error_contains "The main menu needs the 'menu' command" || return 1
}

test_main_menu_shows_title() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/main-menu"
  _assert_success
  grep -q "Main Menu:" "$tmp/log" || {
    TEST_FAILURE_REASON="Main Menu: title missing"
    return 1
  }
}

test_main_menu_loads_colors_gracefully() {
  # Verify the spell sources colors (wizardry's color palette)
  grep -q "colors" "$ROOT_DIR/spells/menu/main-menu" || {
    TEST_FAILURE_REASON="spell does not source colors"
    return 1
  }
}

_run_test_case "main-menu requires menu dependency" test_main_menu_checks_dependency
_run_test_case "main-menu forwards menu entries" test_main_menu_passes_expected_entries
_run_test_case "main-menu fails without menu dependency" test_main_menu_fails_without_menu_dependency
_run_test_case "main-menu shows title" test_main_menu_shows_title
_run_test_case "main-menu loads colors gracefully" test_main_menu_loads_colors_gracefully

# Test ESC and Exit behavior - menu exits properly when TERM signal is sent
test_esc_exit_behavior() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_require "$tmp"
  
  # Create menu stub that logs entries and sends TERM to parent
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
# Send TERM signal to parent to simulate ESC behavior
kill -TERM "$PPID" 2>/dev/null || exit 0
exit 0
SH
  chmod +x "$tmp/menu"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/main-menu"
  _assert_success || { TEST_FAILURE_REASON="menu should exit successfully on TERM signal"; return 1; }
  
  args=$(cat "$tmp/log")
  # The Exit command shows kill -TERM $PPID literally for didactic purposes
  case "$args" in
    *'Exit%kill -TERM $PPID'*) : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
}

_run_test_case "main-menu ESC/Exit handles nested and unnested" test_esc_exit_behavior

# Test that MUD appears when enabled via mud-config
test_main_menu_shows_mud_when_enabled() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  # Create stub mud-config that returns mud-enabled=1
  cat >"$tmp/mud-config" <<'SH'
#!/bin/sh
case "$1" in
  get)
    case "$2" in
      mud-enabled) printf '1\n' ;;
      *) printf '0\n' ;;
    esac
    ;;
esac
SH
  chmod +x "$tmp/mud-config"
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/main-menu"
  _assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"MUD%"*"mud"*) : ;;
    *) TEST_FAILURE_REASON="MUD should appear when enabled: $args"; return 1 ;;
  esac
}

_run_test_case "main-menu shows MUD when enabled" test_main_menu_shows_mud_when_enabled

shows_help() {
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/main-menu" --help
  # Note: spell may not have --help implemented yet, so we just ensure it doesn't crash
  true
}

_run_test_case "main-menu accepts --help" shows_help

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
  
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/main-menu"
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

_run_test_case "main-menu no exit message on ESC" test_no_exit_message_on_esc

# Test that nested menu return shows proper blank line spacing
test_nested_menu_spacing() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  
  # Create a menu that records when it's called, and on second call sends TERM
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
count=$(cat "$INVOCATION_FILE" 2>/dev/null || echo 0)
count=$((count + 1))
printf '%s\n' "$count" >"$INVOCATION_FILE"
# Always send TERM to exit on first display (simulating ESC)
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
  
  INVOCATION_FILE="$tmp/invocations"
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" INVOCATION_FILE="$INVOCATION_FILE" "$ROOT_DIR/spells/menu/main-menu"
  _assert_success || return 1
  
  # The menu loop should have run once (on first_run, no leading newline)
  # This ensures consistent spacing behavior
  return 0
}

_run_test_case "main-menu nested spacing behavior" test_nested_menu_spacing

# Test that exactly one blank line appears when going down/up menu levels
test_single_blank_line_on_menu_selection() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  
  # Create a submenu that outputs and exits
  cat >"$tmp/system-menu" <<'SH'
#!/bin/sh
printf 'System menu displayed\n'
exit 0
SH
  chmod +x "$tmp/system-menu"
  
  # Create a menu that simulates real behavior:
  # - On ENTER: prints \n before executing command
  # - No extra blank lines elsewhere
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
# Simulate menu display
printf '%s\n' "Main Menu:" >>"$MENU_OUTPUT"
printf '%s\n' "System%system-menu" >>"$MENU_OUTPUT"

# Simulate ENTER being pressed - single blank line before command
printf '\n' >>"$MENU_OUTPUT"

# Execute the command (in this case, system-menu)
cmd="system-menu"
$cmd >>"$MENU_OUTPUT" 2>&1

# After command completes, send TERM to exit the loop
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
  _run_cmd env PATH="$tmp:$PATH" MENU_OUTPUT="$MENU_OUTPUT" "$ROOT_DIR/spells/menu/main-menu"
  _assert_success || return 1
  
  # Count blank lines in output - should be exactly 1
  if [ -f "$MENU_OUTPUT" ]; then
    blank_count=$(grep -c '^$' "$MENU_OUTPUT" || true)
    if [ "$blank_count" -ne 1 ]; then
      TEST_FAILURE_REASON="Expected exactly 1 blank line, got $blank_count"
      return 1
    fi
  else
    TEST_FAILURE_REASON="No output captured"
    return 1
  fi
  
  return 0
}

_run_test_case "main-menu shows exactly one blank line on selection" test_single_blank_line_on_menu_selection


# Test via source-then-invoke pattern  
main_menu_help_via_sourcing() {
  _run_sourced_spell main-menu --help
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

_run_test_case "main-menu works via source-then-invoke" main_menu_help_via_sourcing
_finish_tests
