#!/bin/sh
# Test that invoke-wizardry makes imps available without hanging or errors

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test: Core imps are available as commands after sourcing invoke-wizardry
test_core_imps_available() {
  tmpdir=$(_make_tempdir)
  cat > "$tmpdir/test-imps.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry"

# Check that core imps are available as commands
if command -v has >/dev/null 2>&1; then
  printf 'has available\n'
fi
if command -v warn >/dev/null 2>&1; then
  printf 'warn available\n'
fi
if command -v die >/dev/null 2>&1; then
  printf 'die available\n'
fi
if command -v say >/dev/null 2>&1; then
  printf 'say available\n'
fi
EOF
  chmod +x "$tmpdir/test-imps.sh"
  
  _run_cmd sh "$tmpdir/test-imps.sh"
  _assert_success || return 1
  _assert_output_contains "has available" || return 1
  _assert_output_contains "warn available" || return 1
  _assert_output_contains "die available" || return 1
  _assert_output_contains "say available" || return 1
}

# Test: require-command works after invoke-wizardry is sourced
test_require_command_works() {
  tmpdir=$(_make_tempdir)
  cat > "$tmpdir/test-require.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry"

# require-command should work with sh (which always exists)
if "$ROOT_DIR/spells/cantrips/require-command" sh 2>/dev/null; then
  printf 'require-command succeeded\n'
fi
EOF
  chmod +x "$tmpdir/test-require.sh"
  
  _run_cmd sh "$tmpdir/test-require.sh"
  _assert_success || return 1
  _assert_output_contains "require-command succeeded" || return 1
}

# Test: Sourcing invoke-wizardry doesn't hang (timeout after 5 seconds)
test_no_hanging() {
  tmpdir=$(_make_tempdir)
  cat > "$tmpdir/test-hang.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry"
printf 'completed without hanging\n'
EOF
  chmod +x "$tmpdir/test-hang.sh"
  
  # Run with a timeout to detect hanging (5 seconds should be plenty)
  if command -v timeout >/dev/null 2>&1; then
    _run_cmd timeout 5 sh "$tmpdir/test-hang.sh"
  else
    # Fallback if timeout not available
    _run_cmd sh "$tmpdir/test-hang.sh"
  fi
  _assert_success || return 1
  _assert_output_contains "completed without hanging" || return 1
}

# Test: menu spell can be called after invoke-wizardry
test_menu_available() {
  tmpdir=$(_make_tempdir)
  cat > "$tmpdir/test-menu.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry"

# Check that menu is available (just check --help, don't run it)
if command -v menu >/dev/null 2>&1; then
  printf 'menu available\n'
fi
EOF
  chmod +x "$tmpdir/test-menu.sh"
  
  _run_cmd sh "$tmpdir/test-menu.sh"
  _assert_success || return 1
  _assert_output_contains "menu available" || return 1
}

_run_test_case "core imps are available as commands" test_core_imps_available
_run_test_case "require-command works after invoke-wizardry" test_require_command_works
_run_test_case "sourcing invoke-wizardry doesn't hang" test_no_hanging
_run_test_case "menu is available after invoke-wizardry" test_menu_available

_finish_tests
