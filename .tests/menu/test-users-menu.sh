#!/bin/sh
# Test coverage for users-menu spell:
# - Shows usage with --help
# - Sources colors

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/menu/users-menu" --help
  assert_success || return 1
  assert_output_contains "Usage: users-menu" || return 1
}

test_help_h_flag() {
  run_spell "spells/menu/users-menu" -h
  assert_success || return 1
  assert_output_contains "Usage: users-menu" || return 1
}

test_sources_colors() {
  # Verify the spell has a load_colors function
  grep -q "load_colors" "$ROOT_DIR/spells/menu/users-menu" || {
    TEST_FAILURE_REASON="spell does not load colors"
    return 1
  }
}

run_test_case "users-menu shows usage text" test_help
run_test_case "users-menu shows usage with -h" test_help_h_flag
run_test_case "users-menu sources colors" test_sources_colors

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
  
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/users-menu"
  assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *"Exit%exit 113"*) : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
  
}

run_test_case "users-menu ESC/Exit behavior" test_esc_exit_behavior

finish_tests
