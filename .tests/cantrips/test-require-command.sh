#!/bin/sh
# Behavioral cases (derived from --help):
# - require-command succeeds when command exists
# - require-command reports missing commands with default guidance
# - require-command accepts a custom failure message
# - require-command requires at least one argument

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

require_command_succeeds_when_available() {
  run_spell "spells/cantrips/require-command" sh
  assert_success || return 1
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected no stdout"; return 1; }
}

require_command_reports_missing_with_default_message() {
  skip-if-compiled || return $?
  run_spell "spells/cantrips/require-command" definitely-not-a-real-command
  assert_failure || return 1
  assert_error_contains "require-command: The 'definitely-not-a-real-command' command is required." || return 1
  assert_error_contains "core-menu" || return 1
}

require_command_supports_custom_message() {
  run_spell "spells/cantrips/require-command" missing-helper "custom install instructions"
  assert_failure || return 1
  assert_error_contains "custom install instructions" || return 1
}

require_command_installs_when_helper_available() {
  tmp=$(make_tempdir)

  cat >"$tmp/install-missing" <<'SH'
#!/bin/sh
touch "$STUB_DIR/missing"
chmod +x "$STUB_DIR/missing"
SH
  chmod +x "$tmp/install-missing"

  run_cmd env PATH="$tmp:$PATH" STUB_DIR="$tmp" REQUIRE_COMMAND_ASSUME_YES=1 \
    "$ROOT_DIR/spells/cantrips/require-command" missing

  assert_success && assert_path_exists "$tmp/missing"
}

require_command_requires_arguments() {
  skip-if-compiled || return $?
  run_spell "spells/cantrips/require-command"
  assert_failure || return 1
  assert_error_contains "Usage: require-command" || return 1
}

# Test: require-command does not produce "has: command not found" error
test_require_command_no_has_error() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  
  # Create a minimal test that checks require-command doesn't reference missing 'has' command
  # We don't need invoke-wizardry for this - just need imps in PATH
  cat > "$tmpdir/test-require.sh" << 'EOF'
#!/bin/sh
WIZARDRY_DIR="$1"
export WIZARDRY_DIR

# Add imps to PATH so require-wizardry and other imps are available
PATH="$WIZARDRY_DIR/spells/.imps/sys:$WIZARDRY_DIR/spells/.imps/out:$WIZARDRY_DIR/spells/.imps/cond:$PATH"
export PATH

# Call require-command (which should use command -v, not 'has' imp)
"$WIZARDRY_DIR/spells/cantrips/require-command" sh 2>&1 | grep -q "has: command not found" && {
  printf "FAIL: has: command not found error detected\n" >&2
  exit 1
}

printf "SUCCESS: no has command not found error\n"
EOF
  chmod +x "$tmpdir/test-require.sh"
  
  run_cmd sh "$tmpdir/test-require.sh" "$ROOT_DIR"
  assert_success || return 1
  assert_output_contains "SUCCESS: no has command not found error" || return 1
}

# Test: require-command does not produce "warn: command not found" error
test_require_command_no_warn_error() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  
  cat > "$tmpdir/test-warn.sh" << 'EOF'
#!/bin/sh
WIZARDRY_DIR="$1"
export WIZARDRY_DIR

# Add imps to PATH so require-wizardry and other imps are available
PATH="$WIZARDRY_DIR/spells/.imps/sys:$WIZARDRY_DIR/spells/.imps/out:$WIZARDRY_DIR/spells/.imps/cond:$PATH"
export PATH

# Call require-command with a missing command to trigger the warn path
"$WIZARDRY_DIR/spells/cantrips/require-command" definitely-not-a-real-command-xyz 2>&1 | grep -q "warn: command not found" && {
  printf "FAIL: warn: command not found error detected\n" >&2
  exit 1
}

printf "SUCCESS: no warn command not found error\n"
EOF
  chmod +x "$tmpdir/test-warn.sh"
  
  run_cmd sh "$tmpdir/test-warn.sh" "$ROOT_DIR"
  assert_success || return 1
  assert_output_contains "SUCCESS: no warn command not found error" || return 1
}

# Test: Simulate installation - menu is available after invoke-wizardry
test_menu_after_install() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  
  # Create a script that simulates shell startup after installation
  cat > "$tmpdir/simulate-startup.sh" << 'EOF'
#!/bin/sh
set -e

# This simulates what's in the user's .bashrc/.zshrc after installation
WIZARDRY_DIR="$1"
export WIZARDRY_DIR

# Set test mode to prevent env-clear from clearing environment
WIZARDRY_TEST_HELPERS_ONLY=1
export WIZARDRY_TEST_HELPERS_ONLY

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
  run_cmd sh "$tmpdir/simulate-startup.sh" "$ROOT_DIR"
  assert_success || return 1
  assert_output_contains "SUCCESS: menu is available and works" || return 1
}

# Test: Shell startup doesn't hang after installation
test_shell_startup_no_hang() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  
  cat > "$tmpdir/startup-test.sh" << 'EOF'
#!/bin/sh
WIZARDRY_DIR="$1"
export WIZARDRY_DIR

# Set test mode to prevent env-clear from clearing environment
WIZARDRY_TEST_HELPERS_ONLY=1
export WIZARDRY_TEST_HELPERS_ONLY

# This simulates opening a new terminal
. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry"

printf 'shell startup completed\n'
EOF
  chmod +x "$tmpdir/startup-test.sh"
  
  # Run with timeout to detect hanging
  if command -v timeout >/dev/null 2>&1; then
    run_cmd timeout 10 sh "$tmpdir/startup-test.sh" "$ROOT_DIR"
  else
    run_cmd sh "$tmpdir/startup-test.sh" "$ROOT_DIR"
  fi
  assert_success || return 1
  assert_output_contains "shell startup completed" || return 1
}

run_test_case "require-command succeeds when command exists" require_command_succeeds_when_available
run_test_case "require-command reports missing commands with default guidance" require_command_reports_missing_with_default_message
run_test_case "require-command accepts a custom failure message" require_command_supports_custom_message
run_test_case "require-command requires at least one argument" require_command_requires_arguments
run_test_case "require-command installs when helper is available" require_command_installs_when_helper_available
run_test_case "require-command: no 'has: command not found' error" test_require_command_no_has_error
run_test_case "require-command: no 'warn: command not found' error" test_require_command_no_warn_error
run_test_case "menu is available immediately after install" test_menu_after_install
run_test_case "shell startup doesn't hang" test_shell_startup_no_hang


# Test via source-then-invoke pattern  
