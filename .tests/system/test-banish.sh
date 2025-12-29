#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Helper to copy the current wizardry installation to a test directory
# This is much faster than running ./install and gives us a realistic setup
copy_wizardry() {
  dest_dir=$1
  
  # Copy the current wizardry installation
  cp -r "$ROOT_DIR" "$dest_dir" 2>/dev/null || return 1
  
  # Source invoke-wizardry to set up PATH
  if [ -f "$dest_dir/spells/.imps/sys/invoke-wizardry" ]; then
    WIZARDRY_DIR="$dest_dir"
    export WIZARDRY_DIR
    return 0
  fi
  
  return 1
}

test_help() {
  run_spell "spells/system/banish" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "banish" || return 1
}

test_basic_execution() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  # Copy wizardry for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  # Run banish - should validate the installation
  WIZARDRY_DIR="$install_dir" run_spell "spells/system/banish"
  assert_success || return 1
  assert_output_contains "validation checks passed" || return 1
}

test_auto_detect_from_home() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/.wizardry"
  
  # Copy wizardry to HOME/.wizardry for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  # Run without WIZARDRY_DIR set, should auto-detect from HOME
  HOME="$tmpdir" run_spell "spells/system/banish"
  assert_success || return 1
}

test_verbose_mode() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  # Copy wizardry for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  WIZARDRY_DIR="$install_dir" run_spell "spells/system/banish" --verbose
  assert_success || return 1
  # Verbose mode shows "Level 0"
  assert_output_contains "Level 0" || return 1
}

test_non_verbose_has_output() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  # Copy wizardry for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  # Non-verbose mode should have output
  WIZARDRY_DIR="$install_dir" run_spell "spells/system/banish"
  assert_success || return 1
  assert_output_contains "validation checks passed" || return 1
}

test_custom_wizardry_dir() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/custom"
  
  # Copy wizardry to custom location for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  WIZARDRY_LOG_LEVEL=1 run_spell "spells/system/banish" --wizardry-dir "$install_dir"
  assert_success || return 1
  assert_output_contains "Validation complete" || return 1
}

test_missing_invoke_wizardry() {
  tmpdir=$(make_tempdir)
  
  # Create incomplete structure (missing invoke-wizardry)
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  
  # Level 0 now requires invoke-wizardry and will fail without it
  WIZARDRY_DIR="$tmpdir/.wizardry" run_spell "spells/system/banish"
  assert_failure || return 1
  # Should report that wizardry needs to be repaired
}

test_invalid_wizardry_dir() {
  tmpdir=$(make_tempdir)
  
  # Directory exists but no spells subdirectory
  mkdir -p "$tmpdir/.wizardry"
  
  # Level 0 now requires valid wizardry structure
  WIZARDRY_DIR="$tmpdir/.wizardry" run_spell "spells/system/banish"
  assert_failure || return 1
  # Should report that wizardry is not installed
}

run_test_case "banish prints help" test_help
run_test_case "banish basic execution" test_basic_execution
run_test_case "banish auto-detects from HOME" test_auto_detect_from_home
run_test_case "banish verbose mode" test_verbose_mode
run_test_case "banish non-verbose has output" test_non_verbose_has_output
run_test_case "banish custom wizardry-dir" test_custom_wizardry_dir
run_test_case "banish fails without invoke-wizardry" test_missing_invoke_wizardry
run_test_case "banish fails with invalid dir" test_invalid_wizardry_dir

# Test new multi-level functionality with realistic wizardry installation
test_level_0_default() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  # Copy wizardry for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  # Level 0 should be the default
  WIZARDRY_DIR="$install_dir" run_spell "spells/system/banish"
  assert_success || return 1
  assert_output_contains "Level 0" || return 1
}

test_explicit_level_0() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  # Copy wizardry for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  WIZARDRY_DIR="$install_dir" run_spell "spells/system/banish" 0
  assert_success || return 1
  assert_output_contains "Level 0" || return 1
}

test_level_1_requires_menu() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  # Copy wizardry for realistic testing - includes menu
  copy_wizardry "$install_dir" || return 1
  
  # Test level 1 with realistic installation
  WIZARDRY_DIR="$install_dir" WIZARDRY_LOG_LEVEL=1 run_spell "spells/system/banish" 1 --no-tests
  assert_success || return 1
  assert_output_contains "Level 1" || return 1
}

test_no_tests_flag() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  # Copy wizardry for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  WIZARDRY_DIR="$install_dir" run_spell "spells/system/banish" --no-tests
  assert_success || return 1
  # Success is enough - no tests were run
}

test_verbose_shows_level_info() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  # Copy wizardry for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  WIZARDRY_DIR="$install_dir" run_spell "spells/system/banish" 1 --verbose --no-tests
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

# Test that banish is preloaded by invoke-wizardry
test_banish_preloaded() {
  tmpdir=$(make_tempdir)
  
  # Test in a bash subshell with invoke-wizardry
  output=$(cd "$ROOT_DIR" && WIZARDRY_DIR="$ROOT_DIR" WIZARDRY_DEBUG=1 bash --norc --noprofile <<'EOFTEST'
. spells/.imps/sys/invoke-wizardry 2>&1
command -v banish >/dev/null && echo "banish_available"
banish 2>&1 | head -5
EOFTEST
)
  
  # Check that banish was preloaded
  printf '%s\n' "$output" | grep -q "Loading spell: banish" || return 1
  printf '%s\n' "$output" | grep -q "banish_available" || return 1
  # Should show banish function being called
  printf '%s\n' "$output" | grep -q "\[banish\] Function called" || return 1
  # Should NOT trigger command-not-found handler
  ! printf '%s\n' "$output" | grep -q "\[handle-command-not-found\]" || return 1
  
  return 0
}

run_test_case "banish is preloaded by invoke-wizardry" test_banish_preloaded


# Test via source-then-invoke pattern
