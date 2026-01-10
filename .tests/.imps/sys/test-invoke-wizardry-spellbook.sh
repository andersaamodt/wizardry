#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_spellbook_in_path() {
  # Create a test spellbook directory
  tmpdir=$(make_tempdir)
  spellbook_dir="$tmpdir/spellbook"
  mkdir -p "$spellbook_dir"
  
  # Create a custom spell "testcmd" in the spellbook
  cat > "$spellbook_dir/testcmd" << 'EOF'
#!/bin/sh
printf 'testcmd works\n'
EOF
  chmod +x "$spellbook_dir/testcmd"
  
  # Source invoke-wizardry with custom SPELLBOOK_DIR
  export WIZARDRY_DIR="$ROOT_DIR"
  export SPELLBOOK_DIR="$spellbook_dir"
  export WIZARDRY_TEST_HELPERS_ONLY=1
  
  # Source invoke-wizardry
  . "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" || return 1
  
  # Check if SPELLBOOK_DIR is in PATH
  case "$PATH" in
    *"$SPELLBOOK_DIR"*)
      : # SUCCESS
      ;;
    *)
      TEST_FAILURE_REASON="SPELLBOOK_DIR not found in PATH"
      return 1
      ;;
  esac
  
  # Check if custom spell is accessible
  if ! command -v testcmd >/dev/null 2>&1; then
    TEST_FAILURE_REASON="Custom spell testcmd not found in PATH"
    return 1
  fi
  
  # Execute the custom spell
  output=$(testcmd)
  if [ "$output" != "testcmd works" ]; then
    TEST_FAILURE_REASON="Custom spell testcmd did not execute correctly"
    return 1
  fi
}

test_spellbook_subdirectories_in_path() {
  # Create a test spellbook with subdirectories (categories)
  tmpdir=$(make_tempdir)
  spellbook_dir="$tmpdir/spellbook"
  mkdir -p "$spellbook_dir/custom-category"
  
  # Create a custom spell in a subdirectory
  cat > "$spellbook_dir/custom-category/myspell" << 'EOF'
#!/bin/sh
printf 'myspell in custom-category works\n'
EOF
  chmod +x "$spellbook_dir/custom-category/myspell"
  
  # Source invoke-wizardry with custom SPELLBOOK_DIR
  export WIZARDRY_DIR="$ROOT_DIR"
  export SPELLBOOK_DIR="$spellbook_dir"
  export WIZARDRY_TEST_HELPERS_ONLY=1
  
  # Source invoke-wizardry
  . "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" || return 1
  
  # Check if subdirectory is in PATH
  case "$PATH" in
    *"$spellbook_dir/custom-category"*)
      : # SUCCESS
      ;;
    *)
      TEST_FAILURE_REASON="SPELLBOOK_DIR subdirectory not found in PATH"
      return 1
      ;;
  esac
  
  # Check if custom spell in subdirectory is accessible
  if ! command -v myspell >/dev/null 2>&1; then
    TEST_FAILURE_REASON="Custom spell myspell in subdirectory not found in PATH"
    return 1
  fi
}

test_spellbook_takes_priority() {
  # Test that spells in SPELLBOOK_DIR take priority over wizardry spells
  tmpdir=$(make_tempdir)
  spellbook_dir="$tmpdir/spellbook"
  mkdir -p "$spellbook_dir"
  
  # Create a custom version of "say" (an existing imp)
  cat > "$spellbook_dir/say" << 'EOF'
#!/bin/sh
printf 'custom say\n'
EOF
  chmod +x "$spellbook_dir/say"
  
  # Source invoke-wizardry with custom SPELLBOOK_DIR
  export WIZARDRY_DIR="$ROOT_DIR"
  export SPELLBOOK_DIR="$spellbook_dir"
  export WIZARDRY_TEST_HELPERS_ONLY=1
  
  # Source invoke-wizardry
  . "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" || return 1
  
  # Check that SPELLBOOK_DIR appears BEFORE wizardry directories in PATH
  # This ensures custom spells take priority
  spellbook_pos=$(printf '%s' "$PATH" | tr ':' '\n' | grep -n "$SPELLBOOK_DIR" | head -1 | cut -d: -f1)
  wizardry_pos=$(printf '%s' "$PATH" | tr ':' '\n' | grep -n "$WIZARDRY_DIR/spells/.imps/out" | head -1 | cut -d: -f1)
  
  if [ -z "$spellbook_pos" ]; then
    TEST_FAILURE_REASON="SPELLBOOK_DIR not found in PATH"
    return 1
  fi
  
  if [ -z "$wizardry_pos" ]; then
    TEST_FAILURE_REASON="Wizardry directory not found in PATH"
    return 1
  fi
  
  if [ "$spellbook_pos" -gt "$wizardry_pos" ]; then
    TEST_FAILURE_REASON="SPELLBOOK_DIR should appear before wizardry directories in PATH for priority"
    return 1
  fi
}

run_test_case "SPELLBOOK_DIR is added to PATH" test_spellbook_in_path
run_test_case "SPELLBOOK_DIR subdirectories are added to PATH" test_spellbook_subdirectories_in_path
run_test_case "SPELLBOOK_DIR spells take priority over wizardry spells" test_spellbook_takes_priority

finish_tests
