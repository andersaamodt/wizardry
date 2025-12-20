#!/bin/sh
# Test that menu works after invoke-wizardry is sourced
# This validates the Mac install bug fix where menu failed with
# "require-wizardry: command not found"

# Locate the repository root so we can source test-bootstrap
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_menu_help_works() {
  # Create a test script that sources invoke-wizardry and runs menu
  tmp=$(_make_tempdir)
  test_script="$tmp/test-menu.sh"
  
  cat >"$test_script" <<'EOF'
#!/bin/sh
export WIZARDRY_DIR="$1"
# Redirect invoke-wizardry's output to stderr so it doesn't pollute menu's output
. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry" >/dev/null 2>&1 || exit 1
"$WIZARDRY_DIR/spells/cantrips/menu" --help
EOF
  
  chmod +x "$test_script"
  
  # Run the test script
  _run_cmd sh "$test_script" "$ROOT_DIR"
  _assert_success || return 1
  # menu --help outputs to stderr, so check ERROR instead of OUTPUT
  _assert_error_contains "Usage:" || return 1
  _assert_error_contains "menu" || return 1
}

test_require_wizardry_available() {
  # Test that require-wizardry is available after invoke-wizardry is sourced
  tmp=$(_make_tempdir)
  test_script="$tmp/test-require.sh"
  
  cat >"$test_script" <<'EOF'
#!/bin/sh
export WIZARDRY_DIR="$1"
. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null || exit 1
# Try to execute require-wizardry - it should be in PATH or aliased
if command -v require-wizardry >/dev/null 2>&1; then
  echo "require-wizardry is available"
  exit 0
else
  echo "require-wizardry NOT available"
  exit 1
fi
EOF
  
  chmod +x "$test_script"
  
  # Run the test script
  _run_cmd sh "$test_script" "$ROOT_DIR"
  _assert_success || return 1
  _assert_output_contains "require-wizardry is available" || return 1
}

test_imps_sys_in_path() {
  # Test that .imps/sys is in PATH after invoke-wizardry is sourced
  tmp=$(_make_tempdir)
  test_script="$tmp/test-path.sh"
  
  cat >"$test_script" <<'EOF'
#!/bin/sh
export WIZARDRY_DIR="$1"
. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null || exit 1
# Check if .imps/sys is in PATH
case ":$PATH:" in
  *":$WIZARDRY_DIR/spells/.imps/sys:"*)
    echo ".imps/sys is in PATH"
    exit 0
    ;;
  *)
    echo ".imps/sys NOT in PATH"
    exit 1
    ;;
esac
EOF
  
  chmod +x "$test_script"
  
  # Run the test script
  _run_cmd sh "$test_script" "$ROOT_DIR"
  _assert_success || return 1
  _assert_output_contains ".imps/sys is in PATH" || return 1
}

_run_test_case "menu --help works after invoke-wizardry" test_menu_help_works
_run_test_case "require-wizardry available after invoke-wizardry" test_require_wizardry_available
_run_test_case ".imps/sys in PATH after invoke-wizardry" test_imps_sys_in_path
_finish_tests
