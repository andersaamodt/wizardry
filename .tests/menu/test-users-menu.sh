#!/bin/sh
# Test coverage for users-menu spell:
# - Shows usage with --help
# - Sources colors
# - Validates menu entries are forwarded correctly

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
printf '%s %s\n' "$1" "$2" >>"$REQUIRE_LOG"
exit 0
SH
  chmod +x "$tmp/require-command"
}

test_help() {
  _run_spell "spells/menu/users-menu" --help
  _assert_success || return 1
  _assert_output_contains "Usage: users-menu" || return 1
}

test_help_h_flag() {
  _run_spell "spells/menu/users-menu" -h
  _assert_success || return 1
  _assert_output_contains "Usage: users-menu" || return 1
}

test_help_usage_flag() {
  _run_spell "spells/menu/users-menu" --usage
  _assert_success || return 1
  _assert_output_contains "Usage: users-menu" || return 1
}

test_sources_colors() {
  # Verify the spell sources colors (wizardry's color palette)
  grep -q "colors" "$ROOT_DIR/spells/menu/users-menu" || {
    TEST_FAILURE_REASON="spell does not source colors"
    return 1
  }
}

test_users_menu_checks_requirements() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" REQUIRE_LOG="$tmp/req" "$ROOT_DIR/spells/menu/users-menu"
  _assert_success && _assert_path_exists "$tmp/req"
}

test_users_menu_presents_actions() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/users-menu"
  _assert_success
  args=$(cat "$tmp/log")
  # Verify key user management actions are present
  case "$args" in
    *"Users Menu:"*"Change my password%passwd"*"List all users%"*"View my group memberships%groups"*'Exit%kill -TERM $PPID' ) : ;;
    *) TEST_FAILURE_REASON="expected user actions missing: $args"; return 1 ;;
  esac
}

test_users_menu_includes_group_management() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/users-menu"
  _assert_success
  args=$(cat "$tmp/log")
  # Verify group management actions are present
  case "$args" in
    *"List all groups%"*"Create new group%"*"Delete group%"*"Join group%"*"Leave group%"* ) : ;;
    *) TEST_FAILURE_REASON="group management actions missing: $args"; return 1 ;;
  esac
}

test_users_menu_includes_user_admin() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/users-menu"
  _assert_success
  # Check menu log contains expected user admin actions (one per line in log)
  grep -q "Create new user%" "$tmp/log" || {
    TEST_FAILURE_REASON="Create new user action missing"
    return 1
  }
  grep -q "Delete user%" "$tmp/log" || {
    TEST_FAILURE_REASON="Delete user action missing"
    return 1
  }
  grep -q "Add other user to group%" "$tmp/log" || {
    TEST_FAILURE_REASON="Add other user to group action missing"
    return 1
  }
  grep -q "Remove other user from group%" "$tmp/log" || {
    TEST_FAILURE_REASON="Remove other user from group action missing"
    return 1
  }
}

_run_test_case "users-menu shows usage text" test_help
_run_test_case "users-menu shows usage with -h" test_help_h_flag
_run_test_case "users-menu shows usage with --usage" test_help_usage_flag
_run_test_case "users-menu sources colors" test_sources_colors
_run_test_case "users-menu requires menu dependency" test_users_menu_checks_requirements
_run_test_case "users-menu presents user actions" test_users_menu_presents_actions
_run_test_case "users-menu includes group management" test_users_menu_includes_group_management
_run_test_case "users-menu includes user admin actions" test_users_menu_includes_user_admin

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
  
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/users-menu"
  _assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *'Exit%kill -TERM $PPID') : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
}

_run_test_case "users-menu ESC/Exit behavior" test_esc_exit_behavior


# Test via source-then-invoke pattern  
