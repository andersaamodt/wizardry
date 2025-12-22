#!/bin/sh
# Tests for handle-command-not-found spell
# Behavioral cases:
# - handle-command-not-found install adds the hook to rc file
# - handle-command-not-found uninstall removes the hook from rc file
# - handle-command-not-found --help shows usage

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_handle_cnf_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/mud/handle-command-not-found" ]
}

test_handle_cnf_help_shows_usage() {
  _run_spell "spells/.arcana/mud/handle-command-not-found" --help
  _assert_success || return 1
  _assert_output_contains "Usage:" || return 1
  _assert_output_contains "install" || return 1
  _assert_output_contains "uninstall" || return 1
}

test_handle_cnf_requires_action() {
  _run_spell "spells/.arcana/mud/handle-command-not-found"
  _assert_failure || return 1
  _assert_error_contains "Usage:" || return 1
}

test_handle_cnf_installs_hook() {
  tmp=$(_make_tempdir)
  : >"$tmp/rc"
  
  # Install is now deprecated and should just print a message
  _run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/.arcana/mud/handle-command-not-found" install
  _assert_success || return 1
  _assert_error_contains "deprecated" || return 1
  
  # Verify hook was NOT installed (since it's deprecated)
  if grep -q ">>> wizardry command-not-found >>>" "$tmp/rc" 2>/dev/null; then
    TEST_FAILURE_REASON="Hook was installed despite being deprecated"
    return 1
  fi
}

test_handle_cnf_uninstalls_hook() {
  tmp=$(_make_tempdir)
  
  # Manually create an old-style hook for testing uninstall
  cat > "$tmp/rc" << 'EOF'
# >>> wizardry command-not-found >>>
command_not_found_handle() {
  printf '%s: command not found\n' "$1" >&2
  return 127
}
# <<< wizardry command-not-found <<<
EOF
  
  # Verify it was created
  if ! grep -q ">>> wizardry command-not-found >>>" "$tmp/rc"; then
    TEST_FAILURE_REASON="Hook not created for uninstall test"
    return 1
  fi
  
  # Now uninstall it
  _run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/.arcana/mud/handle-command-not-found" uninstall
  _assert_success || return 1
  _assert_output_contains "uninstalled" || return 1
  
  # Verify hook was removed
  if grep -q ">>> wizardry command-not-found >>>" "$tmp/rc"; then
    TEST_FAILURE_REASON="Hook still present after uninstall"
    return 1
  fi
}

test_handle_cnf_uninstall_when_not_installed() {
  tmp=$(_make_tempdir)
  : >"$tmp/rc"
  
  _run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/.arcana/mud/handle-command-not-found" uninstall
  _assert_success || return 1
  _assert_output_contains "not installed" || return 1
}

test_handle_cnf_install_idempotent() {
  tmp=$(_make_tempdir)
  : >"$tmp/rc"
  
  # Install is now deprecated - calling it twice should still work
  _run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/.arcana/mud/handle-command-not-found" install
  _assert_success || return 1
  _assert_error_contains "deprecated" || return 1
  
  _run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/.arcana/mud/handle-command-not-found" install
  _assert_success || return 1
  _assert_error_contains "deprecated" || return 1
}

test_handle_cnf_hook_has_proper_function() {
  # This test is no longer relevant since install is deprecated
  # The hook is now provided by invoke-wizardry, not this spell
  # Just verify the spell shows the deprecation message
  tmp=$(_make_tempdir)
  : >"$tmp/rc"
  
  _run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/.arcana/mud/handle-command-not-found" install
  _assert_success || return 1
  _assert_error_contains "deprecated" || return 1
}

_run_test_case "handle-command-not-found is executable" test_handle_cnf_is_executable
_run_test_case "handle-command-not-found --help shows usage" test_handle_cnf_help_shows_usage
_run_test_case "handle-command-not-found requires action" test_handle_cnf_requires_action
_run_test_case "handle-command-not-found install adds hook" test_handle_cnf_installs_hook
_run_test_case "handle-command-not-found uninstall removes hook" test_handle_cnf_uninstalls_hook
_run_test_case "handle-command-not-found uninstall when not installed" test_handle_cnf_uninstall_when_not_installed
_run_test_case "handle-command-not-found install is idempotent" test_handle_cnf_install_idempotent
_run_test_case "handle-command-not-found hook has proper function" test_handle_cnf_hook_has_proper_function
_finish_tests
