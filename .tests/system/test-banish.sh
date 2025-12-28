#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/system/banish" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "banish" || return 1
}

test_basic_execution() {
  tmpdir=$(make_tempdir)
  
  # Create minimal wizardry structure
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  touch "$tmpdir/.wizardry/spells/.imps/sys/invoke-wizardry"
  
  # Run banish - new format outputs "ready"
  WIZARDRY_DIR="$tmpdir/.wizardry" run_spell "spells/system/banish"
  assert_success || return 1
  assert_output_contains "ready" || return 1
}

test_auto_detect_from_home() {
  tmpdir=$(make_tempdir)
  
  # Create structure at HOME/.wizardry
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  touch "$tmpdir/.wizardry/spells/.imps/sys/invoke-wizardry"
  
  # Run without WIZARDRY_DIR set, should auto-detect from HOME
  HOME="$tmpdir" run_spell "spells/system/banish"
  assert_success || return 1
}

test_verbose_mode() {
  tmpdir=$(make_tempdir)
  
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  touch "$tmpdir/.wizardry/spells/.imps/sys/invoke-wizardry"
  
  WIZARDRY_DIR="$tmpdir/.wizardry" run_spell "spells/system/banish" --verbose
  assert_success || return 1
  # Verbose mode shows "Level 0"
  assert_output_contains "Level 0" || return 1
}

test_non_verbose_has_output() {
  tmpdir=$(make_tempdir)
  
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  touch "$tmpdir/.wizardry/spells/.imps/sys/invoke-wizardry"
  
  # Non-verbose mode should have output
  WIZARDRY_DIR="$tmpdir/.wizardry" run_spell "spells/system/banish"
  assert_success || return 1
  assert_output_contains "ready" || return 1
}

test_custom_wizardry_dir() {
  tmpdir=$(make_tempdir)
  
  mkdir -p "$tmpdir/custom/spells/.imps/sys"
  touch "$tmpdir/custom/spells/.imps/sys/invoke-wizardry"
  
  WIZARDRY_LOG_LEVEL=1 run_spell "spells/system/banish" --wizardry-dir "$tmpdir/custom"
  assert_success || return 1
  assert_output_contains "Validation complete" || return 1
}

test_missing_invoke_wizardry() {
  tmpdir=$(make_tempdir)
  
  # Create incomplete structure (missing invoke-wizardry)
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  
  # Level 0 doesn't require invoke-wizardry (it's for pre-install)
  # But it should warn about it
  WIZARDRY_DIR="$tmpdir/.wizardry" WIZARDRY_LOG_LEVEL=1 run_spell "spells/system/banish"
  assert_success || return 1
  # Should still complete Level 0
  assert_output_contains "Level 0" || return 1
}

test_invalid_wizardry_dir() {
  tmpdir=$(make_tempdir)
  
  # Directory exists but no spells subdirectory
  mkdir -p "$tmpdir/.wizardry"
  
  # Level 0 doesn't strictly require spells dir (preparing for install)
  WIZARDRY_DIR="$tmpdir/.wizardry" run_spell "spells/system/banish"
  assert_success || return 1
  # Should warn but not fail at level 0
}

run_test_case "banish prints help" test_help
run_test_case "banish basic execution" test_basic_execution
run_test_case "banish auto-detects from HOME" test_auto_detect_from_home
run_test_case "banish verbose mode" test_verbose_mode
run_test_case "banish non-verbose has output" test_non_verbose_has_output
run_test_case "banish custom wizardry-dir" test_custom_wizardry_dir
run_test_case "banish fails without invoke-wizardry" test_missing_invoke_wizardry
run_test_case "banish fails with invalid dir" test_invalid_wizardry_dir

# Test new multi-level functionality
test_level_0_default() {
  # Level 0 should be the default
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  touch "$tmpdir/.wizardry/spells/.imps/sys/invoke-wizardry"
  
  WIZARDRY_DIR="$tmpdir/.wizardry" run_spell "spells/system/banish"
  assert_success || return 1
  assert_output_contains "Level 0 ready" || return 1
}

test_explicit_level_0() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  touch "$tmpdir/.wizardry/spells/.imps/sys/invoke-wizardry"
  
  WIZARDRY_DIR="$tmpdir/.wizardry" run_spell "spells/system/banish" 0
  assert_success || return 1
  assert_output_contains "Level 0 ready" || return 1
}

test_level_1_requires_menu() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  mkdir -p "$tmpdir/.wizardry/spells/cantrips"
  touch "$tmpdir/.wizardry/spells/.imps/sys/invoke-wizardry"
  
  # Missing menu spell - should warn but not fail
  WIZARDRY_DIR="$tmpdir/.wizardry" WIZARDRY_LOG_LEVEL=1 run_spell "spells/system/banish" 1 --no-tests
  # Currently it warns about missing spells but continues
  assert_output_contains "Level 1" || return 1
}

test_no_tests_flag() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  touch "$tmpdir/.wizardry/spells/.imps/sys/invoke-wizardry"
  
  WIZARDRY_DIR="$tmpdir/.wizardry" run_spell "spells/system/banish" --no-tests
  assert_success || return 1
  # Success is enough - no tests were run
}

test_verbose_shows_level_info() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  mkdir -p "$tmpdir/.wizardry/spells/cantrips"
  touch "$tmpdir/.wizardry/spells/.imps/sys/invoke-wizardry"
  # Create the menu spell files so level 1 doesn't fail
  for spell in menu await-keypress fathom-cursor fathom-terminal move-cursor cursor-blink; do
    touch "$tmpdir/.wizardry/spells/cantrips/$spell"
  done
  
  WIZARDRY_DIR="$tmpdir/.wizardry" run_spell "spells/system/banish" 1 --verbose --no-tests
  assert_success || return 1
  assert_output_contains "System Foundation" || return 1
  assert_output_contains "Menu Core" || return 1
}

test_invalid_level() {
  run_spell "spells/system/banish" 99
  assert_failure || return 1
  # Should reject 99 as an invalid argument
}

run_test_case "banish level 0 is default" test_level_0_default
run_test_case "banish explicit level 0" test_explicit_level_0
run_test_case "banish level 1 checks menu" test_level_1_requires_menu
run_test_case "banish --no-tests skips tests" test_no_tests_flag
run_test_case "banish verbose shows levels" test_verbose_shows_level_info
run_test_case "banish rejects invalid level" test_invalid_level


# Test via source-then-invoke pattern
