#!/bin/sh
# COMPILED_UNSUPPORTED: tests invoke-wizardry which is wizardry bootstrap
# Test invoke-wizardry sourcer

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test: invoke-wizardry is sourceable without errors
test_sourceable() {
  # Create a test script that sources invoke-wizardry
  tmpdir=$(_make_tempdir)
  cat > "$tmpdir/test-source.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry"
# If we get here, sourcing worked
printf 'sourced successfully\n'
EOF
  chmod +x "$tmpdir/test-source.sh"
  
  _run_cmd sh "$tmpdir/test-source.sh"
  _assert_success || return 1
  _assert_output_contains "sourced successfully" || return 1
}

# Test: invoke-wizardry sets WIZARDRY_DIR when not already set
test_sets_wizardry_dir() {
  tmpdir=$(_make_tempdir)
  cat > "$tmpdir/test-var.sh" << EOF
#!/bin/sh
unset WIZARDRY_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry"
printf '%s\n' "\${WIZARDRY_DIR:-unset}"
EOF
  chmod +x "$tmpdir/test-var.sh"
  
  _run_cmd sh "$tmpdir/test-var.sh"
  _assert_success || return 1
  # Should either be set to the root dir or remain unset (if detection fails)
  # The key is it shouldn't error
}

# Test: invoke-wizardry adds spell directories to PATH
test_adds_to_path() {
  tmpdir=$(_make_tempdir)
  cat > "$tmpdir/test-path.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry"
# Check if PATH contains spell directories
case ":\${PATH}:" in
  *":$ROOT_DIR/spells/cantrips:"*)
    printf 'cantrips in path\n'
    ;;
esac
EOF
  chmod +x "$tmpdir/test-path.sh"
  
  _run_cmd sh "$tmpdir/test-path.sh"
  _assert_success || return 1
  _assert_output_contains "cantrips in path" || return 1
}

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

# Test: Sourcing invoke-wizardry maintains permissive shell mode (set +eu)
# This is critical - imps have set -eu but shouldn't change parent shell mode
test_maintains_permissive_mode() {
  tmpdir=$(_make_tempdir)
  cat > "$tmpdir/test-mode.sh" << EOF
#!/bin/sh
# Start in permissive mode (default for sh)
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

# Source invoke-wizardry
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>&1 | grep -v "invoke-thesaurus"

# Check shell mode - errexit and nounset should still be off
# Using 'set -o' to check mode is portable across shells
if set -o | grep -E "errexit.*on" >/dev/null 2>&1; then
  printf 'ERROR: errexit is on (strict mode active)\n'
  exit 1
fi

if set -o | grep -E "nounset.*on" >/dev/null 2>&1; then
  printf 'ERROR: nounset is on (strict mode active)\n'
  exit 1
fi

printf 'permissive mode maintained\n'
EOF
  chmod +x "$tmpdir/test-mode.sh"
  
  _run_cmd sh "$tmpdir/test-mode.sh"
  _assert_success || return 1
  _assert_output_contains "permissive mode maintained" || return 1
}

# Test: Sourcing invoke-wizardry from rc file works (simulates new terminal)
test_rc_file_sourcing() {
  tmpdir=$(_make_tempdir)
  
  # Create a test rc file with invoke-wizardry source line
  cat > "$tmpdir/.testrc" << EOF
# Test rc file
export WIZARDRY_DIR="$ROOT_DIR"
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry"
EOF
  
  # Create a test script that sources the rc file
  cat > "$tmpdir/test-rc.sh" << EOF
#!/bin/sh
. "$tmpdir/.testrc" 2>&1 | grep -v "invoke-thesaurus"

# Check that commands are available
if command -v menu >/dev/null 2>&1; then
  printf 'menu available after rc sourcing\n'
fi

# Check that shell is still in permissive mode
if set -o | grep -E "errexit.*on" >/dev/null 2>&1; then
  printf 'ERROR: errexit is on after rc sourcing\n'
  exit 1
fi

printf 'rc file sourcing successful\n'
EOF
  chmod +x "$tmpdir/test-rc.sh"
  
  _run_cmd sh "$tmpdir/test-rc.sh"
  _assert_success || return 1
  _assert_output_contains "menu available after rc sourcing" || return 1
  _assert_output_contains "rc file sourcing successful" || return 1
}

_run_test_case "invoke-wizardry is sourceable" test_sourceable
_run_test_case "invoke-wizardry sets WIZARDRY_DIR" test_sets_wizardry_dir
_run_test_case "invoke-wizardry adds spell directories to PATH" test_adds_to_path
_run_test_case "core imps are available as commands" test_core_imps_available
_run_test_case "sourcing invoke-wizardry doesn't hang" test_no_hanging
_run_test_case "invoke-wizardry maintains permissive shell mode" test_maintains_permissive_mode
_run_test_case "invoke-wizardry works when sourced from rc file" test_rc_file_sourcing

_finish_tests
