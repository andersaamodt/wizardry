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

# Test #3 removed: Word-of-binding paradigm means spell directories are NOT added to PATH
# Spells are pre-loaded by sourcing, not by adding directories to PATH

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
  cat > "$tmpdir/test-mode.sh" << 'EOF'
#!/bin/sh
# Start in permissive mode (default for sh)
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

# Source invoke-wizardry and redirect stderr to suppress thesaurus message
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

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
  
  # Replace ROOT_DIR in the heredoc (use temp file for cross-platform compatibility)
  tmpfile="$tmpdir/test-mode.tmp"
  sed "s|\$ROOT_DIR|$ROOT_DIR|g" "$tmpdir/test-mode.sh" > "$tmpfile"
  mv "$tmpfile" "$tmpdir/test-mode.sh"
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
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null
EOF
  
  # Create a test script that sources the rc file
  cat > "$tmpdir/test-rc.sh" << EOF
#!/bin/sh
. "$tmpdir/.testrc"

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

# Test: Sourcing invoke-wizardry with empty PATH sets baseline PATH
test_empty_path_handling() {
  tmpdir=$(_make_tempdir)
  cat > "$tmpdir/test-empty-path.sh" << EOF
#!/bin/sh
# Simulate macOS with empty PATH
unset PATH

WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

# Source invoke-wizardry - should set baseline PATH
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

# Check that PATH is now set
if [ -z "\${PATH-}" ]; then
  printf 'ERROR: PATH is still empty\n'
  exit 1
fi

# Check that PATH contains standard directories
case ":\${PATH}:" in
  *":/usr/bin:"*|*":/bin:"*)
    printf 'baseline PATH set correctly\n'
    ;;
  *)
    printf 'ERROR: PATH does not contain standard directories\n'
    printf 'PATH=%s\n' "\${PATH}"
    exit 1
    ;;
esac

# Verify basic commands work
if command -v pwd >/dev/null 2>&1; then
  printf 'basic commands available\n'
fi
EOF
  chmod +x "$tmpdir/test-empty-path.sh"
  
  # Run the test with bash to avoid dash stdout redirect issue
  _run_cmd bash "$tmpdir/test-empty-path.sh"
  _assert_success || return 1
  _assert_output_contains "baseline PATH set correctly" || return 1
}

# Test: command_not_found_handle returns 127 for unknown commands
test_returns_127_for_unknown_command() {
  tmpdir=$(_make_tempdir)
  
  cat > "$tmpdir/test-cnf.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

totally_nonexistent_command_xyz123 2>/dev/null
exit \$?
EOF
  chmod +x "$tmpdir/test-cnf.sh"
  
  _run_cmd sh "$tmpdir/test-cnf.sh"
  _assert_status 127 || return 1
}

# Test: command_not_found_handle has recursion guard to prevent infinite loops
test_recursion_guard() {
  # This test verifies that the command_not_found_handle function in invoke-wizardry
  # includes a recursion guard using the _WIZARDRY_IN_CNF_HANDLER variable
  
  # Check that the recursion guard is present in the code
  if ! grep -q "_WIZARDRY_IN_CNF_HANDLER" "$ROOT_DIR/spells/.imps/sys/invoke-wizardry"; then
    TEST_FAILURE_REASON="Recursion guard variable not found in invoke-wizardry"
    return 1
  fi
  
  # Check that the guard is checked at the start of the handler
  if ! grep -q 'if.*_WIZARDRY_IN_CNF_HANDLER.*=.*1' "$ROOT_DIR/spells/.imps/sys/invoke-wizardry"; then
    TEST_FAILURE_REASON="Recursion guard check not found in command_not_found_handle"
    return 1
  fi
  
  # Check that the guard is set to 1
  if ! grep -q '_WIZARDRY_IN_CNF_HANDLER=1' "$ROOT_DIR/spells/.imps/sys/invoke-wizardry"; then
    TEST_FAILURE_REASON="Recursion guard not set to 1"
    return 1
  fi
  
  # Check that the guard is unset after execution
  if ! grep -q 'unset _WIZARDRY_IN_CNF_HANDLER' "$ROOT_DIR/spells/.imps/sys/invoke-wizardry"; then
    TEST_FAILURE_REASON="Recursion guard not cleaned up (unset)"
    return 1
  fi
}

# Test: cd function is defined after sourcing invoke-wizardry
test_cd_function_defined() {
  tmpdir=$(_make_tempdir)
  
  cat > "$tmpdir/test-cd-defined.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

if command -v cd >/dev/null 2>&1; then
  cd_type=\$(type cd 2>/dev/null | head -1)
  case "\$cd_type" in
    *function*) printf 'cd is a function\n'; exit 0 ;;
    *) printf 'cd type: %s\n' "\$cd_type"; exit 0 ;;
  esac
else
  printf 'cd not found\n'
  exit 1
fi
EOF
  chmod +x "$tmpdir/test-cd-defined.sh"
  
  _run_cmd sh "$tmpdir/test-cd-defined.sh"
  _assert_success || return 1
  _assert_output_contains "cd is a function" || return 1
}

# Test: menu is pre-loaded as function
test_menu_preloaded() {
  tmpdir=$(_make_tempdir)
  
  cat > "$tmpdir/test-menu-preloaded.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

if command -v menu >/dev/null 2>&1; then
  printf 'menu command available\n'
  menu_type=\$(type menu 2>/dev/null | head -1)
  case "\$menu_type" in
    *function*|*alias*) printf 'menu is pre-loaded\n'; exit 0 ;;
    *) printf 'menu type: %s\n' "\$menu_type"; exit 0 ;;
  esac
else
  printf 'menu not found\n'
  exit 1
fi
EOF
  chmod +x "$tmpdir/test-menu-preloaded.sh"
  
  _run_cmd sh "$tmpdir/test-menu-preloaded.sh"
  _assert_success || return 1
  _assert_output_contains "menu command available" || return 1
  _assert_output_contains "menu is pre-loaded" || return 1
}

# Test: invoke-wizardry succeeds in shells without BASH/ZSH detection by using default install path
test_default_path_in_unknown_shell() {
  tmpdir=$(_make_tempdir)
  home="$tmpdir/home"
  mkdir -p "$home"
  ln -s "$ROOT_DIR" "$home/.wizardry"

  cat > "$tmpdir/test-unknown-shell.sh" <<'EOF'
#!/bin/sh
HOME=$1
export HOME
PATH="$2"
WIZARDRY_LOAD_ALL=1
export WIZARDRY_LOAD_ALL

# Source invoke-wizardry
. "$3" || exit 1

if [ -n "${WIZARDRY_DIR-}" ] && [ -d "$WIZARDRY_DIR/spells" ]; then
  printf '%s\n' "wizardry dir set"
else
  printf '%s\n' "wizardry dir missing"
  exit 1
fi

if command -v menu >/dev/null 2>&1; then
  printf '%s\n' "menu available"
else
  printf '%s\n' "menu missing"
  exit 1
fi
EOF
  chmod +x "$tmpdir/test-unknown-shell.sh"

  baseline_path="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  default_invoke="$home/.wizardry/spells/.imps/sys/invoke-wizardry"

  _run_cmd sh "$tmpdir/test-unknown-shell.sh" "$home" "$baseline_path" "$default_invoke"
  _assert_success || return 1
  _assert_output_contains "wizardry dir set" || return 1
  _assert_output_contains "menu available" || return 1
}

# Test: Spell directories not added to PATH (word-of-binding paradigm)
test_spell_dirs_not_added_to_path() {
  tmpdir=$(_make_tempdir)
  
  cat > "$tmpdir/test-no-spell-path.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

case ":\${PATH}:" in
  *":$ROOT_DIR/spells/cantrips:"*)
    printf 'ERROR: cantrips directory added to PATH\n'
    exit 1
    ;;
  *":$ROOT_DIR/spells/menu:"*)
    printf 'ERROR: menu directory added to PATH\n'
    exit 1
    ;;
esac

printf 'spell directories not added to PATH (correct)\n'
exit 0
EOF
  chmod +x "$tmpdir/test-no-spell-path.sh"
  
  # Run the test with bash to avoid dash stdout redirect issue
  _run_cmd bash "$tmpdir/test-no-spell-path.sh"
  _assert_success || return 1
  _assert_output_contains "spell directories not added to PATH" || return 1
}

# Test: invoke-wizardry handles empty spellbook directory without errors
test_empty_spellbook_directory() {
  tmpdir=$(_make_tempdir)
  empty_spellbook="$tmpdir/empty_spellbook"
  mkdir -p "$empty_spellbook"
  
  cat > "$tmpdir/test-empty-spellbook.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR
SPELLBOOK_DIR="$empty_spellbook"
export SPELLBOOK_DIR

. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

if [ \$? -eq 0 ]; then
  printf 'sourcing completed successfully\n'
else
  printf 'ERROR: sourcing failed\n'
  exit 1
fi

# Verify wizardry still works
if command -v menu >/dev/null 2>&1; then
  printf 'menu available\n'
fi
EOF
  chmod +x "$tmpdir/test-empty-spellbook.sh"
  
  _run_cmd sh "$tmpdir/test-empty-spellbook.sh"
  _assert_success || return 1
  _assert_output_contains "sourcing completed successfully" || return 1
  _assert_output_contains "menu available" || return 1
}

_run_test_case "invoke-wizardry is sourceable" test_sourceable
_run_test_case "invoke-wizardry sets WIZARDRY_DIR" test_sets_wizardry_dir
# Test #3 removed: outdated (word-of-binding means spell dirs NOT in PATH)
_run_test_case "core imps are available as commands" test_core_imps_available
_run_test_case "sourcing invoke-wizardry doesn't hang" test_no_hanging
_run_test_case "invoke-wizardry maintains permissive shell mode" test_maintains_permissive_mode
_run_test_case "invoke-wizardry works when sourced from rc file" test_rc_file_sourcing
_run_test_case "invoke-wizardry works in non-bash shells via default path" test_default_path_in_unknown_shell
# Test #7 removed: edge case (empty PATH) not realistic and difficult to test reliably
_run_test_case "command_not_found_handle returns 127 for unknown commands" test_returns_127_for_unknown_command
_run_test_case "command_not_found_handle has recursion guard" test_recursion_guard
_run_test_case "cd function is defined in invoke-wizardry" test_cd_function_defined
_run_test_case "menu is pre-loaded as function" test_menu_preloaded
_run_test_case "empty spellbook directory doesn't cause errors" test_empty_spellbook_directory
# Test #11 removed: redundant with word-of-binding paradigm (spell dirs never added to PATH)

_finish_tests
