#!/bin/sh
# Test Mac installation scenario - verify menu is available immediately

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test: Simulate what happens after installation - source invoke-wizardry and check menu
test_menu_after_install() {
  tmpdir=$(_make_tempdir)
  
  # Create a script that simulates shell startup after installation
  cat > "$tmpdir/simulate-startup.sh" << 'EOF'
#!/bin/sh
set -e

# This simulates what's in the user's .bashrc/.zshrc after installation
WIZARDRY_DIR="$1"
export WIZARDRY_DIR

# Source invoke-wizardry (this is what the install script adds to rc file)
. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry"

# Try to run menu --help (what a user would do)
if command -v menu >/dev/null 2>&1; then
  # Menu is available - try running it with --help
  if menu --help >/dev/null 2>&1; then
    printf 'SUCCESS: menu is available and works\n'
  else
    printf 'ERROR: menu command exists but --help failed\n' >&2
    exit 1
  fi
else
  printf 'ERROR: menu command not found\n' >&2
  exit 1
fi
EOF
  chmod +x "$tmpdir/simulate-startup.sh"
  
  # Run the simulation
  _run_cmd sh "$tmpdir/simulate-startup.sh" "$ROOT_DIR"
  _assert_success || return 1
  _assert_output_contains "SUCCESS: menu is available and works" || return 1
}

# Test: Verify no "command not found" errors when running menu
test_no_command_not_found_errors() {
  tmpdir=$(_make_tempdir)
  
  cat > "$tmpdir/check-errors.sh" << 'EOF'
#!/bin/sh
WIZARDRY_DIR="$1"
export WIZARDRY_DIR

# Source invoke-wizardry
. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry" 2>&1 | grep -i "command not found" && {
  printf 'ERROR: command not found during invoke-wizardry\n' >&2
  exit 1
}

# Try to get menu help
menu --help 2>&1 | grep -i "command not found" && {
  printf 'ERROR: command not found during menu\n' >&2
  exit 1
}

printf 'SUCCESS: no command not found errors\n'
EOF
  chmod +x "$tmpdir/check-errors.sh"
  
  _run_cmd sh "$tmpdir/check-errors.sh" "$ROOT_DIR"
  _assert_success || return 1
  _assert_output_contains "SUCCESS: no command not found errors" || return 1
}

# Test: Verify shell doesn't hang on startup
test_shell_startup_no_hang() {
  tmpdir=$(_make_tempdir)
  
  cat > "$tmpdir/startup-test.sh" << 'EOF'
#!/bin/sh
WIZARDRY_DIR="$1"
export WIZARDRY_DIR

# This simulates opening a new terminal
. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry"

printf 'shell startup completed\n'
EOF
  chmod +x "$tmpdir/startup-test.sh"
  
  # Run with timeout to detect hanging
  if command -v timeout >/dev/null 2>&1; then
    _run_cmd timeout 10 sh "$tmpdir/startup-test.sh" "$ROOT_DIR"
  else
    _run_cmd sh "$tmpdir/startup-test.sh" "$ROOT_DIR"
  fi
  _assert_success || return 1
  _assert_output_contains "shell startup completed" || return 1
}

_run_test_case "menu is available immediately after install" test_menu_after_install
_run_test_case "no command not found errors" test_no_command_not_found_errors
_run_test_case "shell startup doesn't hang" test_shell_startup_no_hang

_finish_tests
