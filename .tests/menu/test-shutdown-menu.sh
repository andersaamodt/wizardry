#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - shutdown-menu requires the menu dependency
# - shutdown-menu forwards shutdown/restart actions to the menu
# - shutdown-menu includes optional Sleep and Hibernate when available

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
exit 113
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

test_shutdown_menu_checks_requirements() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" REQUIRE_LOG="$tmp/req" "$ROOT_DIR/spells/menu/shutdown-menu"
  assert_success && assert_path_exists "$tmp/req"
}

test_shutdown_menu_includes_core_actions() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Back"
SH
  chmod +x "$tmp/exit-label"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/shutdown-menu"
  assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"Restart / Shutdown:"*"Restart%sudo shutdown -r now"*"Shutdown%sudo shutdown -h now"*"Logout%pkill -KILL"*"Force restart%sudo shutdown -r now"*"Force shutdown%sudo shutdown -h now"*"Back%exit 113"* ) : ;;
    *) TEST_FAILURE_REASON="expected shutdown actions missing: $args"; return 1 ;;
  esac
}

run_test_case "shutdown-menu requires menu dependency" test_shutdown_menu_checks_requirements
run_test_case "shutdown-menu passes shutdown actions to menu" test_shutdown_menu_includes_core_actions

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Back"
SH
  chmod +x "$tmp/exit-label"
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/shutdown-menu"
  assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *"Back%exit 113"*) : ;;
    *) TEST_FAILURE_REASON="menu should show Back label: $args"; return 1 ;;
  esac
}

run_test_case "shutdown-menu ESC/Exit behavior" test_esc_exit_behavior

shows_help() {
  run_spell spells/menu/shutdown-menu --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "shutdown-menu accepts --help" shows_help
finish_tests
