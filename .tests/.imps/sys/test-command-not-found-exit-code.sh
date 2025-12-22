#!/bin/sh
# Test that command_not_found_handle returns exit code 127 for unknown commands

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test: command_not_found_handle returns 127 for unknown commands
test_returns_127_for_unknown_command() {
  tmpdir=$(_make_tempdir)
  
  # Create a test script that sources invoke-wizardry and tries an unknown command
  cat > "$tmpdir/test-cnf.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

# Source invoke-wizardry to set up command_not_found_handle
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

# Try to run a command that doesn't exist
# The command_not_found_handle should catch this and return 127
totally_nonexistent_command_xyz123 2>/dev/null
exit \$?
EOF
  chmod +x "$tmpdir/test-cnf.sh"
  
  # Run the script and check exit code
  _run_cmd sh "$tmpdir/test-cnf.sh"
  
  # Should fail with exit code 127 (command not found)
  _assert_status 127 || return 1
}

# Test: command_not_found_handle succeeds (exit 0) when command exists via word-of-binding
test_succeeds_for_valid_spell() {
  tmpdir=$(_make_tempdir)
  
  # Create a test script that sources invoke-wizardry and tries a valid spell
  cat > "$tmpdir/test-valid.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

# Source invoke-wizardry
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

# Try to run menu --help (should succeed via word-of-binding or PATH)
menu --help >/dev/null 2>&1
exit \$?
EOF
  chmod +x "$tmpdir/test-valid.sh"
  
  _run_cmd sh "$tmpdir/test-valid.sh"
  _assert_success || return 1
}

# Test: Bash-specific command_not_found_handle returns 127
test_bash_command_not_found_handle() {
  # Only run if bash is available
  if ! command -v bash >/dev/null 2>&1; then
    return 0  # Skip test if bash not available
  fi
  
  tmpdir=$(_make_tempdir)
  
  cat > "$tmpdir/test-bash-cnf.sh" << EOF
#!/bin/bash
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

# Source invoke-wizardry (sets up command_not_found_handle)
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

# Try unknown command
totally_nonexistent_command_xyz123 2>/dev/null
exit \$?
EOF
  chmod +x "$tmpdir/test-bash-cnf.sh"
  
  _run_cmd bash "$tmpdir/test-bash-cnf.sh"
  _assert_status 127 || return 1
}

_run_test_case "command_not_found_handle returns 127 for unknown commands" test_returns_127_for_unknown_command
_run_test_case "command_not_found_handle succeeds for valid spells" test_succeeds_for_valid_spell
_run_test_case "bash command_not_found_handle returns 127" test_bash_command_not_found_handle

_finish_tests
