#!/bin/sh
# Tests for handle-command-not-found spell
# Behavioral cases:
# - handle-command-not-found install adds the hook to rc file
# - handle-command-not-found uninstall removes the hook from rc file
# - handle-command-not-found --help shows usage

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


test_handle_cnf_is_executable() {
  [ -x "$ROOT_DIR/spells/install/mud/handle-command-not-found" ]
}

test_handle_cnf_help_shows_usage() {
  run_spell "spells/install/mud/handle-command-not-found" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "install" || return 1
  assert_output_contains "uninstall" || return 1
}

test_handle_cnf_requires_action() {
  run_spell "spells/install/mud/handle-command-not-found"
  assert_failure || return 1
  assert_error_contains "Usage:" || return 1
}

test_handle_cnf_installs_hook() {
  tmp=$(make_tempdir)
  : >"$tmp/rc"
  
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/handle-command-not-found" install
  assert_success || return 1
  assert_output_contains "installed" || return 1
  
  # Verify hook was installed
  if ! grep -q ">>> wizardry command-not-found >>>" "$tmp/rc"; then
    TEST_FAILURE_REASON="Hook opening marker not found in rc file"
    return 1
  fi
  if ! grep -q "command_not_found_handle" "$tmp/rc"; then
    TEST_FAILURE_REASON="command_not_found_handle function not found in rc file"
    return 1
  fi
}

test_handle_cnf_uninstalls_hook() {
  tmp=$(make_tempdir)
  
  # First install the hook
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/handle-command-not-found" install
  assert_success || return 1
  
  # Verify it was installed
  if ! grep -q ">>> wizardry command-not-found >>>" "$tmp/rc"; then
    TEST_FAILURE_REASON="Hook not installed for uninstall test"
    return 1
  fi
  
  # Now uninstall it
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/handle-command-not-found" uninstall
  assert_success || return 1
  assert_output_contains "uninstalled" || return 1
  
  # Verify hook was removed
  if grep -q ">>> wizardry command-not-found >>>" "$tmp/rc"; then
    TEST_FAILURE_REASON="Hook still present after uninstall"
    return 1
  fi
}

test_handle_cnf_uninstall_when_not_installed() {
  tmp=$(make_tempdir)
  : >"$tmp/rc"
  
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/handle-command-not-found" uninstall
  assert_success || return 1
  assert_output_contains "not installed" || return 1
}

test_handle_cnf_install_idempotent() {
  tmp=$(make_tempdir)
  : >"$tmp/rc"
  
  # Install twice
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/handle-command-not-found" install
  assert_success || return 1
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/handle-command-not-found" install
  assert_success || return 1
  
  # Count how many times the marker appears - should be exactly 1
  count=$(grep -c ">>> wizardry command-not-found >>>" "$tmp/rc" || true)
  if [ "$count" != "1" ]; then
    TEST_FAILURE_REASON="Multiple hook blocks installed: found $count markers"
    return 1
  fi
}

test_handle_cnf_hook_has_proper_function() {
  tmp=$(make_tempdir)
  : >"$tmp/rc"
  
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/handle-command-not-found" install
  assert_success || return 1
  
  # Verify the function has proper content
  if ! grep -q "return 127" "$tmp/rc"; then
    TEST_FAILURE_REASON="command_not_found_handle should return 127"
    return 1
  fi
  if ! grep -q "menu" "$tmp/rc"; then
    TEST_FAILURE_REASON="command_not_found_handle should mention menu"
    return 1
  fi
}

run_test_case "handle-command-not-found is executable" test_handle_cnf_is_executable
run_test_case "handle-command-not-found --help shows usage" test_handle_cnf_help_shows_usage
run_test_case "handle-command-not-found requires action" test_handle_cnf_requires_action
run_test_case "handle-command-not-found install adds hook" test_handle_cnf_installs_hook
run_test_case "handle-command-not-found uninstall removes hook" test_handle_cnf_uninstalls_hook
run_test_case "handle-command-not-found uninstall when not installed" test_handle_cnf_uninstall_when_not_installed
run_test_case "handle-command-not-found install is idempotent" test_handle_cnf_install_idempotent
run_test_case "handle-command-not-found hook has proper function" test_handle_cnf_hook_has_proper_function
finish_tests
