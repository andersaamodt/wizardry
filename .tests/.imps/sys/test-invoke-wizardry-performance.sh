#!/bin/sh
# Test new terminal simulation and menu availability
# This test ensures that sourcing invoke-wizardry doesn't hang and that menu is available

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test: Sourcing invoke-wizardry completes within reasonable time
test_invoke_wizardry_performance() {
  tmpdir=$(_make_tempdir)
  
  # Create a test script that sources invoke-wizardry and measures time
  cat > "$tmpdir/test-source-timing.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

start_time=\$(date +%s)
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null
end_time=\$(date +%s)

elapsed=\$((end_time - start_time))
printf 'elapsed_seconds=%s\n' "\$elapsed"

# Check if menu is available
if command -v menu >/dev/null 2>&1; then
  printf 'menu_available=yes\n'
else
  printf 'menu_available=no\n'
fi
EOF
  chmod +x "$tmpdir/test-source-timing.sh"
  
  # Run with timeout to prevent actual hanging
  if command -v timeout >/dev/null 2>&1; then
    _run_cmd timeout 30 sh "$tmpdir/test-source-timing.sh"
  else
    _run_cmd sh "$tmpdir/test-source-timing.sh"
  fi
  
  _assert_success || return 1
  _assert_output_contains "elapsed_seconds=" || return 1
  _assert_output_contains "menu_available=yes" || return 1
  
  # Extract elapsed time and check it's reasonable (less than 10 seconds)
  elapsed=$(printf '%s\n' "$OUTPUT" | grep 'elapsed_seconds=' | cut -d= -f2)
  if [ -n "$elapsed" ] && [ "$elapsed" -gt 10 ]; then
    TEST_FAILURE_REASON="invoke-wizardry took too long: ${elapsed}s (expected < 10s)"
    return 1
  fi
}

# Test: Menu is callable after sourcing invoke-wizardry
test_menu_callable() {
  tmpdir=$(_make_tempdir)
  
  # Create a test script that sources invoke-wizardry and calls menu --help
  cat > "$tmpdir/test-menu.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

# Try to call menu --help (should not hang)
if command -v menu >/dev/null 2>&1; then
  menu --help >/dev/null 2>&1 && printf 'menu_help_works=yes\n' || printf 'menu_help_failed=yes\n'
else
  printf 'menu_not_found=yes\n'
fi
EOF
  chmod +x "$tmpdir/test-menu.sh"
  
  # Run with timeout
  if command -v timeout >/dev/null 2>&1; then
    _run_cmd timeout 10 sh "$tmpdir/test-menu.sh"
  else
    _run_cmd sh "$tmpdir/test-menu.sh"
  fi
  
  _assert_success || return 1
  _assert_output_contains "menu_help_works=yes" || return 1
}

# Test: No spell sourcing causes shell to exit
test_no_spell_causes_exit() {
  # This test checks that spells with "exit" statements don't affect the parent shell
  # when sourced during invoke-wizardry initialization
  
  tmpdir=$(_make_tempdir)
  mkdir -p "$tmpdir/test-wizardry/spells/test-cat"
  
  # Create a spell with exit statement (like menu's require-wizardry || exit 1)
  cat > "$tmpdir/test-wizardry/spells/test-cat/bad-spell" << 'EOF'
#!/bin/sh

bad_spell() {
  # This should not execute during sourcing
  exit 1
}

# Self-execute pattern
case "$0" in
  */bad-spell) bad_spell "$@" ;; esac
EOF
  
  # Create a minimal invoke script
  cat > "$tmpdir/test-invoke.sh" << 'EOF'
#!/bin/sh
WIZARDRY_DIR="$1"
export WIZARDRY_DIR

# Simulate the spell sourcing loop from invoke-wizardry
for spell_cat in "$WIZARDRY_DIR"/spells/*; do
  [ -d "$spell_cat" ] || continue
  for spell in "$spell_cat"/*; do
    [ -f "$spell" ] && [ -r "$spell" ] || continue
    spell_name=$(basename "$spell")
    spell_true_name=$(printf '%s' "$spell_name" | sed 's/-/_/g')
    
    if grep -qE "^[[:space:]]*${spell_true_name}[[:space:]]*\\(\\)" "$spell" 2>/dev/null; then
      # Source the spell
      . "$spell" 2>/dev/null || true
      
      if command -v "$spell_true_name" >/dev/null 2>&1; then
        alias "$spell_name=$spell_true_name" 2>/dev/null || true
      fi
    fi
  done
done

printf 'sourcing_completed=yes\n'
EOF
  chmod +x "$tmpdir/test-invoke.sh"
  
  _run_cmd sh "$tmpdir/test-invoke.sh" "$tmpdir/test-wizardry"
  _assert_success || return 1
  _assert_output_contains "sourcing_completed=yes" || return 1
}

# Test: Recursive sourcing is prevented
test_no_recursive_sourcing() {
  # Check that invoke-wizardry has the _WIZARDRY_INVOKED guard
  if ! grep -q '_WIZARDRY_INVOKED' "$ROOT_DIR/spells/.imps/sys/invoke-wizardry"; then
    TEST_FAILURE_REASON="invoke-wizardry missing recursion guard"
    return 1
  fi
  
  # Test actual behavior
  tmpdir=$(_make_tempdir)
  cat > "$tmpdir/test-double-source.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

# Source invoke-wizardry twice
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

printf 'double_source_completed=yes\n'
EOF
  chmod +x "$tmpdir/test-double-source.sh"
  
  _run_cmd sh "$tmpdir/test-double-source.sh"
  _assert_success || return 1
  _assert_output_contains "double_source_completed=yes" || return 1
}

# Test: Command not found handler doesn't create infinite loops
test_cnf_no_infinite_loop() {
  tmpdir=$(_make_tempdir)
  
  # Create a test that tries to trigger infinite loop
  cat > "$tmpdir/test-cnf-loop.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

# Try a non-existent command (should use command_not_found_handle)
nonexistent_command_12345 2>/dev/null
result=\$?

printf 'cnf_returned=%s\n' "\$result"
EOF
  chmod +x "$tmpdir/test-cnf-loop.sh"
  
  # Run with timeout to detect infinite loops
  if command -v timeout >/dev/null 2>&1; then
    _run_cmd timeout 5 sh "$tmpdir/test-cnf-loop.sh"
  else
    _run_cmd sh "$tmpdir/test-cnf-loop.sh"
  fi
  
  _assert_success || return 1
  _assert_output_contains "cnf_returned=" || return 1
}

_run_test_case "invoke-wizardry completes quickly" test_invoke_wizardry_performance
_run_test_case "menu is callable after sourcing" test_menu_callable
_run_test_case "spell exit statements don't affect shell" test_no_spell_causes_exit
_run_test_case "recursive sourcing is prevented" test_no_recursive_sourcing
_run_test_case "command_not_found_handle no infinite loop" test_cnf_no_infinite_loop

_finish_tests
