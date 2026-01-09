#!/bin/sh
# Test that jump-trash can be invoked via "jump trash" and sources correctly

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_jump_trash_via_parse() {
  # Create test trash directory
  stub=$(make_tempdir)
  trash_dir="$stub/Trash"
  mkdir -p "$trash_dir"
  
  # Create detect-trash stub
  cat >"$stub/detect-trash" <<STUB
#!/bin/sh
printf '%s\n' "$trash_dir"
STUB
  chmod +x "$stub/detect-trash"
  
  # Create a shell script that sources jump trash via the gloss
  # This simulates what happens when user types "jump trash" in their shell
  cat >"$stub/test-script.sh" <<SCRIPT
#!/bin/sh
export WIZARDRY_DIR="$ROOT_DIR"
export PATH="$stub:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/lex:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/paths:$PATH"
export SPELLBOOK_DIR="$stub/.spellbook"
mkdir -p "\$SPELLBOOK_DIR"

# Source invoke-wizardry to get glosses
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry"

# Now try "jump trash" 
cd "$stub" || exit 1
jump trash
pwd
SCRIPT
  chmod +x "$stub/test-script.sh"
  
  # Run the test script
  output=$("$stub/test-script.sh" 2>&1)
  status=$?
  
  # Check that it succeeded and changed to trash directory
  if [ $status -eq 0 ]; then
    if printf '%s\n' "$output" | grep -q "$trash_dir"; then
      return 0
    else
      fail "jump trash did not change to trash directory. Output: $output"
      return 1
    fi
  else
    fail "jump trash failed with status $status. Output: $output"
    return 1
  fi
}

test_jump_trash_direct_execution_fails() {
  # Direct execution should fail with helpful error message
  run_spell "spells/arcane/jump-trash"
  assert_failure
  assert_output_contains "cannot be cast directly"
  assert_output_contains "Invoke it with"
}

test_jump_trash_sourcing_works() {
  skip-if-compiled || return $?
  stub=$(make_tempdir)
  trash_dir="$stub/Trash"
  mkdir -p "$trash_dir"
  
  # Create detect-trash stub
  cat >"$stub/detect-trash" <<STUB
#!/bin/sh
printf '%s\n' "$trash_dir"
STUB
  chmod +x "$stub/detect-trash"
  
  # Test that sourcing works
  cat >"$stub/test-source.sh" <<SCRIPT
#!/bin/sh
export PATH="$stub:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/str:$PATH"
export WIZARDRY_DIR="$ROOT_DIR"
cd "$stub" || exit 1
. "$ROOT_DIR/spells/arcane/jump-trash"
pwd
SCRIPT
  chmod +x "$stub/test-source.sh"
  
  output=$("$stub/test-source.sh" 2>&1)
  status=$?
  
  if [ $status -eq 0 ] && printf '%s\n' "$output" | grep -q "$trash_dir"; then
    return 0
  else
    fail "Sourcing jump-trash failed. Status: $status, Output: $output"
    return 1
  fi
}

run_test_case "jump trash via parse works" test_jump_trash_via_parse
run_test_case "jump-trash direct execution shows helpful error" test_jump_trash_direct_execution_fails
run_test_case "jump-trash works when sourced" test_jump_trash_sourcing_works
finish_tests
