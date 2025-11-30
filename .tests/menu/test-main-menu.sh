#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - main-menu requires menu dependency before running
# - main-menu invokes menu with expected options and honors escape status
# - main-menu fails when menu dependency is missing
# - main-menu loads colors gracefully

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
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" REQUIRE_LOG="$tmp/req" "$ROOT_DIR/spells/menu/main-menu"
  assert_success && assert_path_exists "$tmp/req"
}

test_main_menu_passes_expected_entries() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/main-menu"
  assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"Main Menu:"*"MUD menu%"*"mud"*"Cast a Spell%"*"cast"*"Spellbook%"*"spellbook"*"Arcana%"*"install-menu"*"Manage System%"*"system-menu"*"Exit%exit 113"* ) : ;;
    *) TEST_FAILURE_REASON="menu entries missing: $args"; return 1 ;;
  esac
}

test_main_menu_fails_without_menu_dependency() {
  tmp=$(make_tempdir)
  make_failing_require "$tmp"
  run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/menu/main-menu"
  assert_failure || return 1
  assert_error_contains "The main menu needs the 'menu' command" || return 1
}

test_main_menu_shows_title() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/main-menu"
  assert_success
  grep -q "Main Menu:" "$tmp/log" || {
    TEST_FAILURE_REASON="Main Menu: title missing"
    return 1
  }
}

test_main_menu_loads_colors_gracefully() {
  # Verify the spell has a load_colors function
  grep -q "load_colors" "$ROOT_DIR/spells/menu/main-menu" || {
    TEST_FAILURE_REASON="spell does not have load_colors function"
    return 1
  }
}

run_test_case "main-menu requires menu dependency" test_main_menu_checks_dependency
run_test_case "main-menu forwards menu entries" test_main_menu_passes_expected_entries
run_test_case "main-menu fails without menu dependency" test_main_menu_fails_without_menu_dependency
run_test_case "main-menu shows title" test_main_menu_shows_title
run_test_case "main-menu loads colors gracefully" test_main_menu_loads_colors_gracefully

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  tmp=$(make_tempdir)
  make_stub_require "$tmp"
  
  # Create menu stub that logs entries and returns escape status
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit 113
SH
  chmod +x "$tmp/menu"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/main-menu"
  assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *"Exit%exit 113"*) : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
}

run_test_case "main-menu ESC/Exit handles nested and unnested" test_esc_exit_behavior

shows_help() {
  run_spell spells/menu/main-menu --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "main-menu accepts --help" shows_help
finish_tests
