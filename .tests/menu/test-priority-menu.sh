#!/bin/sh
# Test coverage for priority-menu spell:
# - Shows usage with --help
# - Requires file argument
# - Sources colors

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/menu/priority-menu" --help
  assert_success || return 1
  assert_output_contains "Usage: priority-menu" || return 1
}

test_requires_file_argument() {
  run_spell "spells/menu/priority-menu"
  assert_failure || return 1
  assert_error_contains "file argument required" || return 1
}

test_help_h_flag() {
  run_spell "spells/menu/priority-menu" -h
  assert_success || return 1
  assert_output_contains "Usage: priority-menu" || return 1
}

run_test_case "priority-menu shows usage text" test_help
run_test_case "priority-menu requires file argument" test_requires_file_argument
run_test_case "priority-menu shows usage with -h" test_help_h_flag

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  tmp=$(make_tempdir)
  
  # Create menu stub that logs entries and returns escape status
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
  
  cat >"$tmp/read-magic" <<'SH'
#!/bin/sh
echo "Error: The attribute does not exist."
SH
  chmod +x "$tmp/read-magic"
  
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Create test file
  touch "$tmp/testfile"
  
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/priority-menu" "$tmp/testfile"
  assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *"Exit%exit 113"*) : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
  
}

run_test_case "priority-menu ESC/Exit behavior" test_esc_exit_behavior

finish_tests
