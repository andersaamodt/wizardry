#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_load_cd_hook_through_parse() {
  # Set up clean environment
  tmpdir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir"
  printf "parse-enabled=1\ncd-look=0\n" > "$tmpdir/.mud"
  
  # Unset cd if it was defined
  unset -f cd 2>/dev/null || true
  
  # Try to load cd hook via parse
  set -- load cd hook
  . "$ROOT_DIR/spells/.imps/lex/parse" 2>&1
  
  # Check if cd function is defined
  if type cd 2>/dev/null | grep -q "function"; then
    return 0
  else
    TEST_FAILURE_REASON="cd function not defined after sourcing load-cd-hook via parse"
    return 1
  fi
}

test_load_cd_hook_changes_directory() {
  # Set up clean environment
  tmpdir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir"
  printf "parse-enabled=1\ncd-look=0\n" > "$tmpdir/.mud"
  
  # Unset cd if it was defined
  unset -f cd 2>/dev/null || true
  
  # Load cd hook via parse
  set -- load cd hook
  . "$ROOT_DIR/spells/.imps/lex/parse" 2>&1
  
  # Create test directory
  testdir=$(make_tempdir)
  original_dir=$(pwd -P)
  
  # Use the cd function to change directory
  cd "$testdir" >/dev/null 2>&1
  current_dir=$(pwd -P)
  
  # Go back
  command cd "$original_dir" >/dev/null 2>&1
  
  # Check if we were in the test directory
  if [ "$current_dir" = "$testdir" ]; then
    return 0
  else
    TEST_FAILURE_REASON="cd function didn't change directory (expected $testdir, got $current_dir)"
    return 1
  fi
}

test_arcana_spells_found_by_parse() {
  # Verify that parse can find spells in .arcana directories
  tmpdir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir"
  printf "parse-enabled=1\n" > "$tmpdir/.mud"
  
  # Try to find load-cd-hook which is in .arcana/mud/
  set -- load cd hook
  . "$ROOT_DIR/spells/.imps/lex/parse" 2>&1
  result=$?
  
  # If parse succeeded (found and sourced the spell), it should return 0
  [ $result -eq 0 ]
}

run_test_case "parse finds load-cd-hook in .arcana" test_load_cd_hook_through_parse
run_test_case "cd function from load-cd-hook changes directory" test_load_cd_hook_changes_directory  
run_test_case "parse searches .arcana directories" test_arcana_spells_found_by_parse
finish_tests
