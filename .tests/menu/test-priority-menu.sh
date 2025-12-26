#!/bin/sh
# Test coverage for priority-menu spell:
# - Shows usage with --help
# - Requires file argument
# - Sources colors
# - Shows menu entries for file operations

set -eu

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
exit 0
SH
  chmod +x "$tmp/require-command"
}

make_read_magic_stub() {
  tmp=$1
  cat >"$tmp/read-magic" <<'SH'
#!/bin/sh
echo "read-magic: attribute does not exist."
SH
  chmod +x "$tmp/read-magic"
}

test_help() {
  _run_spell "spells/menu/priority-menu" --help
  _assert_success || return 1
  _assert_output_contains "Usage: priority-menu" || return 1
}

test_requires_file_argument() {
  skip-if-compiled || return $?
  _run_spell "spells/menu/priority-menu"
  _assert_failure || return 1
  _assert_error_contains "file path required" || return 1
}

test_help_h_flag() {
  _run_spell "spells/menu/priority-menu" -h
  _assert_success || return 1
  _assert_output_contains "Usage: priority-menu" || return 1
}

test_help_usage_flag() {
  _run_spell "spells/menu/priority-menu" --usage
  _assert_success || return 1
  _assert_output_contains "Usage: priority-menu" || return 1
}

test_priority_menu_presents_actions() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  make_read_magic_stub "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Create test file
  touch "$tmp/testfile"
  
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/priority-menu" "$tmp/testfile"
  _assert_success || return 1
  
  # Verify key actions are present
  grep -q "Prioritize" "$tmp/log" || {
    TEST_FAILURE_REASON="Prioritize action missing"
    return 1
  }
  grep -q "Check%" "$tmp/log" || {
    TEST_FAILURE_REASON="Check action missing"
    return 1
  }
  grep -q "Discard" "$tmp/log" || {
    TEST_FAILURE_REASON="Discard action missing"
    return 1
  }
  grep -q "Edit Card%" "$tmp/log" || {
    TEST_FAILURE_REASON="Edit Card action missing"
    return 1
  }
  grep -q "Browse Within%" "$tmp/log" || {
    TEST_FAILURE_REASON="Browse Within action missing"
    return 1
  }
}

test_priority_menu_shows_filename_in_title() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  make_read_magic_stub "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Create test file with recognizable name
  touch "$tmp/myspecialfile"
  
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/priority-menu" "$tmp/myspecialfile"
  _assert_success || return 1
  
  # Verify filename is shown in menu title
  grep -q "myspecialfile" "$tmp/log" || {
    TEST_FAILURE_REASON="filename should appear in menu title"
    return 1
  }
}

test_priority_menu_shows_uncheck_when_checked() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  
  # Create read-magic stub that says item is checked
  cat >"$tmp/read-magic" <<'SH'
#!/bin/sh
if [ "$2" = "checked" ]; then
  echo "true"
else
  echo "read-magic: attribute does not exist."
fi
SH
  chmod +x "$tmp/read-magic"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  touch "$tmp/testfile"
  
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/priority-menu" "$tmp/testfile"
  _assert_success || return 1
  
  # When checked, should show "Uncheck" instead of "Check"
  grep -q "Uncheck%" "$tmp/log" || {
    TEST_FAILURE_REASON="Uncheck action should appear when item is checked"
    return 1
  }
}

_run_test_case "priority-menu shows usage text" test_help
_run_test_case "priority-menu requires file argument" test_requires_file_argument
_run_test_case "priority-menu shows usage with -h" test_help_h_flag
_run_test_case "priority-menu shows usage with --usage" test_help_usage_flag
_run_test_case "priority-menu presents expected actions" test_priority_menu_presents_actions
_run_test_case "priority-menu shows filename in title" test_priority_menu_shows_filename_in_title
_run_test_case "priority-menu shows uncheck when checked" test_priority_menu_shows_uncheck_when_checked

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  make_read_magic_stub "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Create test file
  touch "$tmp/testfile"
  
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/priority-menu" "$tmp/testfile"
  _assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *'Exit%kill -TERM $PPID') : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
}

_run_test_case "priority-menu ESC/Exit behavior" test_esc_exit_behavior


# Test via source-then-invoke pattern  
priority_menu_help_via_sourcing() {
  _run_sourced_spell priority-menu --help
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

_run_test_case "priority-menu works via source-then-invoke" priority_menu_help_via_sourcing
_finish_tests
