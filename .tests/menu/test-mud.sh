#!/bin/sh
# Behavioral cases (derived from --help):
# - mud menu validates dependencies before launching actions

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

mud_requires_menu_dependency() {
  stub_dir=$(make_tempdir)
  cat <<'STUB' >"$stub_dir/require-command"
#!/bin/sh
printf '%s\n' "require-command stub: $*" >&2
exit 1
STUB
  chmod +x "$stub_dir/require-command"

  run_cmd env REQUIRE_COMMAND="$stub_dir/require-command" PATH="$stub_dir:$PATH" "$ROOT_DIR/spells/menu/mud"
  assert_failure || return 1
  assert_error_contains "The MUD menu needs the 'menu' command" || return 1
}

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/menu/mud" ]
}

shows_help() {
  run_spell spells/menu/mud --help
  true
}

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
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/mud"
  assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *"Exit%exit 113"*) : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
}

run_test_case "mud menu requires menu dependency" mud_requires_menu_dependency
run_test_case "menu/mud is executable" spell_is_executable
run_test_case "mud shows help" shows_help
run_test_case "mud ESC/Exit behavior" test_esc_exit_behavior

finish_tests
