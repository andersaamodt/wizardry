#!/bin/sh
# Behavioral cases (derived from --help):
# - require-command succeeds when command exists
# - require-command reports missing commands with default guidance
# - require-command accepts a custom failure message
# - require-command requires at least one argument

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

require_command_succeeds_when_available() {
  _run_spell "spells/cantrips/require-command" sh
  _assert_success || return 1
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected no stdout"; return 1; }
}

require_command_reports_missing_with_default_message() {
  skip-if-compiled || return $?
  _run_spell "spells/cantrips/require-command" definitely-not-a-real-command
  _assert_failure || return 1
  _assert_error_contains "require-command: The 'definitely-not-a-real-command' command is required." || return 1
  _assert_error_contains "core-menu" || return 1
}

require_command_supports_custom_message() {
  _run_spell "spells/cantrips/require-command" missing-helper "custom install instructions"
  _assert_failure || return 1
  _assert_error_contains "custom install instructions" || return 1
}

require_command_installs_when_helper_available() {
  tmp=$(_make_tempdir)

  cat >"$tmp/install-missing" <<'SH'
#!/bin/sh
touch "$STUB_DIR/missing"
chmod +x "$STUB_DIR/missing"
SH
  chmod +x "$tmp/install-missing"

  _run_cmd env PATH="$tmp:$PATH" STUB_DIR="$tmp" REQUIRE_COMMAND_ASSUME_YES=1 \
    "$ROOT_DIR/spells/cantrips/require-command" missing

  _assert_success && _assert_path_exists "$tmp/missing"
}

require_command_requires_arguments() {
  skip-if-compiled || return $?
  _run_spell "spells/cantrips/require-command"
  _assert_failure || return 1
  _assert_error_contains "Usage: require-command" || return 1
}

# Test: require-command does not produce "has: command not found" error
test_require_command_no_has_error() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  
  cat > "$tmpdir/test-require.sh" << 'EOF'
#!/bin/sh
WIZARDRY_DIR="$1"
export WIZARDRY_DIR

# Source invoke-wizardry like shell startup does
. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry"

# Call require-command (which menu uses via require imp)
# This should not produce "has: command not found" error
"$WIZARDRY_DIR/spells/cantrips/require-command" sh 2>&1 | grep -q "has: command not found" && {
  printf "FAIL: has: command not found error detected\n" >&2
  exit 1
}

printf "SUCCESS: no has command not found error\n"
EOF
  chmod +x "$tmpdir/test-require.sh"
  
  _run_cmd sh "$tmpdir/test-require.sh" "$ROOT_DIR"
  _assert_success || return 1
  _assert_output_contains "SUCCESS: no has command not found error" || return 1
}

# Test: require-command does not produce "warn: command not found" error
test_require_command_no_warn_error() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  
  cat > "$tmpdir/test-warn.sh" << 'EOF'
#!/bin/sh
WIZARDRY_DIR="$1"
export WIZARDRY_DIR

. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry"

# Call require-command with a missing command to trigger the warn path
"$WIZARDRY_DIR/spells/cantrips/require-command" definitely-not-a-real-command-xyz 2>&1 | grep -q "warn: command not found" && {
  printf "FAIL: warn: command not found error detected\n" >&2
  exit 1
}

printf "SUCCESS: no warn command not found error\n"
EOF
  chmod +x "$tmpdir/test-warn.sh"
  
  _run_cmd sh "$tmpdir/test-warn.sh" "$ROOT_DIR"
  _assert_success || return 1
_assert_output_contains "SUCCESS: no warn command not found error" || return 1
}

# Test: Simulate installation - menu is available after invoke-wizardry
test_menu_after_install() {
  skip-if-compiled || return $?
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

test_menu_available_in_zsh_after_install() {
  skip-if-compiled || return $?
  if ! command -v zsh >/dev/null 2>&1; then
    _test_skip "menu available in zsh after install" "zsh not installed"
    return 0
  fi

  _run_cmd env WIZARDRY_DIR="$ROOT_DIR" zsh -f -c '
    . "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry" >/dev/null 2>&1
    command -v menu >/dev/null 2>&1 && menu --help >/dev/null 2>&1
  '
  _assert_success || return 1
}

# Test: Shell startup doesn't hang after installation
test_shell_startup_no_hang() {
  skip-if-compiled || return $?
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

_run_test_case "require-command succeeds when command exists" require_command_succeeds_when_available
_run_test_case "require-command reports missing commands with default guidance" require_command_reports_missing_with_default_message
_run_test_case "require-command accepts a custom failure message" require_command_supports_custom_message
_run_test_case "require-command requires at least one argument" require_command_requires_arguments
_run_test_case "require-command installs when helper is available" require_command_installs_when_helper_available
_run_test_case "require-command: no 'has: command not found' error" test_require_command_no_has_error
_run_test_case "require-command: no 'warn: command not found' error" test_require_command_no_warn_error
_run_test_case "menu is available immediately after install" test_menu_after_install
_run_test_case "menu is available in zsh after install" test_menu_available_in_zsh_after_install
_run_test_case "shell startup doesn't hang" test_shell_startup_no_hang

_finish_tests
