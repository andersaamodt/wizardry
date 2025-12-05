#!/bin/sh
# Test coverage for users-menu spell:
# - Shows usage with --help
# - Sources colors
# - Validates menu entries are forwarded correctly

set -eu

# Setup test environment
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
ROOT_DIR=$_test_dir
_sys_path=${PATH:-/usr/local/bin:/usr/bin:/bin}
PATH="$ROOT_DIR/spells:$ROOT_DIR/spells/.imps"
for _d in "$ROOT_DIR/spells/.imps"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
for _d in "$ROOT_DIR/spells"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
PATH="$PATH:$_sys_path"
WIZARDRY_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/wizardry-test.XXXXXX")
export ROOT_DIR PATH WIZARDRY_TMPDIR

# Test state
_pass=0 _fail=0

# Run command and capture output
run_cmd() {
  _o=$(mktemp "$WIZARDRY_TMPDIR/o.XXXXXX"); _e=$(mktemp "$WIZARDRY_TMPDIR/e.XXXXXX")
  STATUS=0; "$@" >"$_o" 2>"$_e" || STATUS=$?
  OUTPUT=$(cat "$_o"); ERROR=$(cat "$_e"); rm -f "$_o" "$_e"
}
run_spell() { _s=$1; shift; run_cmd "$ROOT_DIR/$_s" "$@"; }

# Assertions (call imps with captured state)
assert_success() { test-assert-success "$STATUS" "$ERROR"; }
assert_failure() { test-assert-failure "$STATUS"; }
assert_status() { test-assert-status "$STATUS" "$1" "$ERROR"; }
assert_output_contains() { test-assert-output-contains "$OUTPUT" "$1"; }
assert_error_contains() { test-assert-error-contains "$ERROR" "$1"; }
assert_file_contains() { test-assert-file-contains "$1" "$2"; }
assert_path_exists() { test-assert-path-exists "$1"; }
assert_path_missing() { test-assert-path-missing "$1"; }

# Fixture helpers
make_tempdir() { test-make-tempdir; }
make_fixture() { test-make-fixture; }
write_apt_stub() { test-write-apt-stub "$1"; }
write_sudo_stub() { test-write-sudo-stub "$1"; }
write_command_stub() { test-write-command-stub "$1" "$2"; }
write_pkgin_stub() { test-write-pkgin-stub "$1"; }
provide_basic_tools() { test-provide-basic-tools "$1"; }
link_tools() { test-link-tools "$@"; }

# Test runner
run_test_case() {
  _d=$1; _f=$2
  if "$_f"; then _pass=$((_pass+1)); printf 'PASS %s\n' "$_d"
  else _fail=$((_fail+1)); printf 'FAIL %s\n' "$_d"; fi
}
finish_tests() {
  _t=$((_pass+_fail))
  printf '%s/%s tests passed' "$_pass" "$_t"
  [ "$_fail" -gt 0 ] && printf ' (%s failed)\n' "$_fail" && return 1
  printf '\n'
}


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
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" REQUIRE_LOG="$tmp/req" "$ROOT_DIR/spells/menu/users-menu"
  assert_success && assert_path_exists "$tmp/req"
}

test_users_menu_presents_actions() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/users-menu"
  assert_success
  args=$(cat "$tmp/log")
  # Verify key user management actions are present
  case "$args" in
    *"Users Menu:"*"Change my password%passwd"*"List all users%"*"View my group memberships%groups"*'Exit%kill -TERM $PPID' ) : ;;
    *) TEST_FAILURE_REASON="expected user actions missing: $args"; return 1 ;;
  esac
}

test_users_menu_includes_group_management() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/users-menu"
  assert_success
  args=$(cat "$tmp/log")
  # Verify group management actions are present
  case "$args" in
    *"List all groups%"*"Create new group%"*"Delete group%"*"Join group%"*"Leave group%"* ) : ;;
    *) TEST_FAILURE_REASON="group management actions missing: $args"; return 1 ;;
  esac
}

test_users_menu_includes_user_admin() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
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
  grep -q "Add other user to group%" "$tmp/log" || {
    TEST_FAILURE_REASON="Add other user to group action missing"
    return 1
  }
  grep -q "Remove other user from group%" "$tmp/log" || {
    TEST_FAILURE_REASON="Remove other user from group action missing"
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
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  
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

finish_tests
