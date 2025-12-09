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
  
  # Create detect-rc-file stub
  cat >"$tmp/detect-rc-file" <<EOF
#!/bin/sh
printf '%s\n' '$tmp/rc'
EOF
  chmod +x "$tmp/detect-rc-file"
  
  _run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.arcana/mud/handle-command-not-found" install
  _assert_success || return 1
  _assert_output_contains "installed" || return 1
  
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
  tmp=$(_make_tempdir)
  
  # First install the hook
  # Create detect-rc-file stub
  cat >"$tmp/detect-rc-file" <<EOF
#!/bin/sh
printf '%s\n' '$tmp/rc'
EOF
  chmod +x "$tmp/detect-rc-file"
  
  _run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.arcana/mud/handle-command-not-found" install
  _assert_success || return 1
  
  # Verify it was installed
  if ! grep -q ">>> wizardry command-not-found >>>" "$tmp/rc"; then
    TEST_FAILURE_REASON="Hook not installed for uninstall test"
    return 1
  fi
  
  # Now uninstall it
  # Create detect-rc-file stub
  cat >"$tmp/detect-rc-file" <<EOF
#!/bin/sh
printf '%s\n' '$tmp/rc'
EOF
  chmod +x "$tmp/detect-rc-file"
  
  _run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.arcana/mud/handle-command-not-found" uninstall
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
  
  # Create detect-rc-file stub
  cat >"$tmp/detect-rc-file" <<EOF
#!/bin/sh
printf '%s\n' '$tmp/rc'
EOF
  chmod +x "$tmp/detect-rc-file"
  
  _run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.arcana/mud/handle-command-not-found" uninstall
  _assert_success || return 1
  _assert_output_contains "not installed" || return 1
}

test_handle_cnf_install_idempotent() {
  tmp=$(_make_tempdir)
  : >"$tmp/rc"
  
  # Install twice
  # Create detect-rc-file stub
  cat >"$tmp/detect-rc-file" <<EOF
#!/bin/sh
printf '%s\n' '$tmp/rc'
EOF
  chmod +x "$tmp/detect-rc-file"
  
  _run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.arcana/mud/handle-command-not-found" install
  _assert_success || return 1
  # Create detect-rc-file stub
  cat >"$tmp/detect-rc-file" <<EOF
#!/bin/sh
printf '%s\n' '$tmp/rc'
EOF
  chmod +x "$tmp/detect-rc-file"
  
  _run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.arcana/mud/handle-command-not-found" install
  _assert_success || return 1
  
  # Count how many times the marker appears - should be exactly 1
  count=$(grep -c ">>> wizardry command-not-found >>>" "$tmp/rc" || true)
  if [ "$count" != "1" ]; then
    TEST_FAILURE_REASON="Multiple hook blocks installed: found $count markers"
    return 1
  fi
}

test_handle_cnf_hook_has_proper_function() {
  tmp=$(_make_tempdir)
  : >"$tmp/rc"
  
  # Create detect-rc-file stub
  cat >"$tmp/detect-rc-file" <<EOF
#!/bin/sh
printf '%s\n' '$tmp/rc'
EOF
  chmod +x "$tmp/detect-rc-file"
  
  _run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.arcana/mud/handle-command-not-found" install
  _assert_success || return 1
  
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

_run_test_case "handle-command-not-found is executable" test_handle_cnf_is_executable
_run_test_case "handle-command-not-found --help shows usage" test_handle_cnf_help_shows_usage
_run_test_case "handle-command-not-found requires action" test_handle_cnf_requires_action
_run_test_case "handle-command-not-found install adds hook" test_handle_cnf_installs_hook
_run_test_case "handle-command-not-found uninstall removes hook" test_handle_cnf_uninstalls_hook
_run_test_case "handle-command-not-found uninstall when not installed" test_handle_cnf_uninstall_when_not_installed
_run_test_case "handle-command-not-found install is idempotent" test_handle_cnf_install_idempotent
_run_test_case "handle-command-not-found hook has proper function" test_handle_cnf_hook_has_proper_function
_finish_tests
