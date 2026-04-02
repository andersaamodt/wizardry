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

test_help_usage_flag() {
  run_spell "spells/menu/users-menu" --usage
  assert_success || return 1
  assert_output_contains "Usage: users-menu" || return 1
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
  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-require-command "$tmp"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" REQUIRE_LOG="$tmp/req" "$ROOT_DIR/spells/menu/users-menu"
  assert_success && assert_path_exists "$tmp/req"
}

test_users_menu_presents_actions() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-require-command "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/users-menu"
  assert_success
  args=$(cat "$tmp/log")
  case "$(uname -s 2>/dev/null || printf unknown)" in
    Darwin)
      case "$args" in
        *"Users Menu:"*"Change my password%passwd"*"List local users%dscl . -list /Users"*"View my group memberships%id -Gn"*'Exit%kill -TERM $PPID' ) : ;;
        *) TEST_FAILURE_REASON="expected macOS user actions missing: $args"; return 1 ;;
      esac
      ;;
    *)
      case "$args" in
        *"Users Menu:"*"Change my password%passwd"*"List all users%cut -d: -f1 /etc/passwd"*"View my group memberships%id -Gn"*'Exit%kill -TERM $PPID' ) : ;;
        *) TEST_FAILURE_REASON="expected user actions missing: $args"; return 1 ;;
      esac
      ;;
  esac
}

test_users_menu_includes_group_management() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-require-command "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/users-menu"
  assert_success
  args=$(cat "$tmp/log")
  case "$(uname -s 2>/dev/null || printf unknown)" in
    Darwin)
      printf '%s' "$args" | grep -F 'List local groups%dscl . -list /Groups' >/dev/null 2>&1 || {
        TEST_FAILURE_REASON="macOS list groups action missing: $args"
        return 1
      }
      printf '%s' "$args" | grep -F "Create new group%groupname=\$(ask-text 'Enter new group name:') && sudo dseditgroup -o create \"\$groupname\"" >/dev/null 2>&1 || {
        TEST_FAILURE_REASON="macOS create group action missing: $args"
        return 1
      }
      printf '%s' "$args" | grep -F "Delete group%groupname=\$(ask-text 'Enter group to delete:') && sudo dseditgroup -o delete \"\$groupname\"" >/dev/null 2>&1 || {
        TEST_FAILURE_REASON="macOS delete group action missing: $args"
        return 1
      }
      printf '%s' "$args" | grep -F "Join group%groupname=\$(ask-text 'Enter group name to join:') && sudo dseditgroup -o edit -a \"$USER\" -t user \"\$groupname\"" >/dev/null 2>&1 || {
        TEST_FAILURE_REASON="macOS join group action missing: $args"
        return 1
      }
      printf '%s' "$args" | grep -F "Leave group%groupname=\$(ask-text 'Enter group name to leave:') && sudo dseditgroup -o edit -d \"$USER\" -t user \"\$groupname\"" >/dev/null 2>&1 || {
        TEST_FAILURE_REASON="macOS leave group action missing: $args"
        return 1
      }
      ;;
    *)
      printf '%s' "$args" | grep -F 'List all groups%cut -d: -f1 /etc/group' >/dev/null 2>&1 || {
        TEST_FAILURE_REASON="list groups action missing: $args"
        return 1
      }
      printf '%s' "$args" | grep -F "Create new group%groupname=\$(ask-text 'Enter new group name:') && sudo groupadd \"\$groupname\"" >/dev/null 2>&1 || {
        TEST_FAILURE_REASON="create group action missing: $args"
        return 1
      }
      printf '%s' "$args" | grep -F "Delete group%groupname=\$(ask-text 'Enter group to delete:') && sudo groupdel \"\$groupname\"" >/dev/null 2>&1 || {
        TEST_FAILURE_REASON="delete group action missing: $args"
        return 1
      }
      printf '%s' "$args" | grep -F "Join group%groupname=\$(ask-text 'Enter group name to join:') && sudo usermod -a -G \"\$groupname\" \"$USER\"" >/dev/null 2>&1 || {
        TEST_FAILURE_REASON="join group action missing: $args"
        return 1
      }
      printf '%s' "$args" | grep -F "Leave group%groupname=\$(ask-text 'Enter group name to leave:') && sudo gpasswd -d \"$USER\" \"\$groupname\"" >/dev/null 2>&1 || {
        TEST_FAILURE_REASON="leave group action missing: $args"
        return 1
      }
      ;;
  esac
}

test_users_menu_includes_user_admin() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-require-command "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/users-menu"
  assert_success
  # Check menu log contains expected user admin actions (one per line in log)
  grep -q "Create new user%" "$tmp/log" || {
    TEST_FAILURE_REASON="Create new user action missing"
    return 1
  }
  grep -q "Delete user%" "$tmp/log" || {
    TEST_FAILURE_REASON="Delete user action missing"
    return 1
  }
  grep -q "Add another user to a group%" "$tmp/log" || {
    TEST_FAILURE_REASON="Add another user to a group action missing"
    return 1
  }
  grep -q "Remove another user from a group%" "$tmp/log" || {
    TEST_FAILURE_REASON="Remove another user from a group action missing"
    return 1
  }
}

run_test_case "users-menu shows usage text" test_help
run_test_case "users-menu shows usage with -h" test_help_h_flag
run_test_case "users-menu shows usage with --usage" test_help_usage_flag
run_test_case "users-menu sources colors" test_sources_colors
run_test_case "users-menu requires menu dependency" test_users_menu_checks_requirements
run_test_case "users-menu presents user actions" test_users_menu_presents_actions
run_test_case "users-menu includes group management" test_users_menu_includes_group_management
run_test_case "users-menu includes user admin actions" test_users_menu_includes_user_admin

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-require-command "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/users-menu"
  assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *'Exit%kill -TERM $PPID') : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
}

run_test_case "users-menu ESC/Exit behavior" test_esc_exit_behavior


# Test via source-then-invoke pattern  

finish_tests
