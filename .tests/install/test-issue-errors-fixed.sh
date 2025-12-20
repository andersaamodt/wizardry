#!/bin/sh
# Test that the specific errors mentioned in the issue are fixed

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test: require-command does not produce "has: command not found" error
test_require_command_no_has_error() {
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

# Test: menu command works without hanging or errors
test_menu_no_errors() {
  tmpdir=$(_make_tempdir)
  
  cat > "$tmpdir/test-menu-errors.sh" << 'EOF'
#!/bin/sh
WIZARDRY_DIR="$1"
export WIZARDRY_DIR

. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry"

# Try to run menu --help and check for command not found errors
menu --help 2>&1 | grep -i "command not found" && {
  printf "FAIL: command not found error in menu output\n" >&2
  exit 1
}

printf "SUCCESS: menu works without command not found errors\n"
EOF
  chmod +x "$tmpdir/test-menu-errors.sh"
  
  # Run with timeout to ensure it doesn't hang
  if command -v timeout >/dev/null 2>&1; then
    _run_cmd timeout 10 sh "$tmpdir/test-menu-errors.sh" "$ROOT_DIR"
  else
    _run_cmd sh "$tmpdir/test-menu-errors.sh" "$ROOT_DIR"
  fi
  _assert_success || return 1
  _assert_output_contains "SUCCESS: menu works without command not found errors" || return 1
}

_run_test_case "require-command: no 'has: command not found' error" test_require_command_no_has_error
_run_test_case "require-command: no 'warn: command not found' error" test_require_command_no_warn_error
_run_test_case "menu: no command not found errors" test_menu_no_errors

_finish_tests
