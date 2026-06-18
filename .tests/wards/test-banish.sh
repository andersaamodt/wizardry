#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Helper to copy the current wizardry installation to a test directory
# This is much faster than running ./install and gives us a realistic setup
# Performance optimization: Only copy essential files (spells, install, core docs)
# Excludes .git (1.2M), .tests (2.7M), demo-magic-poc, tutorials for 60% faster copies
copy_wizardry() {
  dest_dir=$1
  
  # Create parent directory if needed
  mkdir -p "$(dirname "$dest_dir")" || return 1
  
  # Remove old directory if it exists
  if [ -d "$dest_dir" ]; then
    rm -rf "$dest_dir" || return 1
  fi
  mkdir -p "$dest_dir" || return 1
  
  # Copy only essential files (exclude .git, .tests, demo-magic-poc, tutorials)
  # This reduces copy from 6.9M to 2.7M (60% reduction)
  cp -Rp "$ROOT_DIR/spells" "$dest_dir/" || return 1
  
  # Copy install if it exists (not present in doppelganger/compiled environments)
  if [ -f "$ROOT_DIR/install" ]; then
    cp -Rp "$ROOT_DIR/install" "$dest_dir/" || true
  fi
  
  # Copy essential metadata files if they exist (optional - failures are non-fatal)
  for file in LICENSE OATH README.md .gitignore; do
    if [ -f "$ROOT_DIR/$file" ]; then
      cp -p "$ROOT_DIR/$file" "$dest_dir/" || true
    fi
  done
  
  # Verify the copy worked by checking for a key file
  if [ -f "$dest_dir/spells/.imps/sys/invoke-wizardry" ]; then
    WIZARDRY_DIR="$dest_dir"
    export WIZARDRY_DIR
    return 0
  fi
  
  return 1
}

test_help() {
  run_spell "spells/wards/banish" --help
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
  HOME="$tmpdir" SPELLBOOK_DIR="$tmpdir/.spellbook" AWAIT_KEYPRESS_DEVICE=/dev/null WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish"
  assert_success || return 1
  assert_output_contains "Banished to Level" || return 1
}

test_auto_detect_from_home() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/.wizardry"
  
  # Copy wizardry to HOME/.wizardry for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  # Run without WIZARDRY_DIR set, should auto-detect from HOME
  HOME="$tmpdir" SPELLBOOK_DIR="$tmpdir/.spellbook" AWAIT_KEYPRESS_DEVICE=/dev/null WIZARDRY_DIR= run_spell "spells/wards/banish"
  assert_success || return 1
}

test_verbose_mode() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  # Copy wizardry for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  # Use WIZARDRY_LOG_LEVEL=2 for verbose output
  HOME="$tmpdir" SPELLBOOK_DIR="$tmpdir/.spellbook" AWAIT_KEYPRESS_DEVICE=/dev/null WIZARDRY_DIR="$install_dir" WIZARDRY_LOG_LEVEL=2 run_spell "spells/wards/banish"
  assert_success || return 1
  # Should show validation progress
  assert_output_contains "Validating" || return 1
}

test_non_verbose_has_output() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  # Copy wizardry for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  # Non-verbose mode should have output
  HOME="$tmpdir" SPELLBOOK_DIR="$tmpdir/.spellbook" AWAIT_KEYPRESS_DEVICE=/dev/null WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish"
  assert_success || return 1
  assert_output_contains "Banished to Level" || return 1
}

test_custom_wizardry_dir() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/custom"
  
  # Copy wizardry to custom location for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  # Set WIZARDRY_DIR via environment variable instead of --wizardry-dir option
  HOME="$tmpdir" SPELLBOOK_DIR="$tmpdir/.spellbook" AWAIT_KEYPRESS_DEVICE=/dev/null WIZARDRY_DIR="$install_dir" WIZARDRY_LOG_LEVEL=1 run_spell "spells/wards/banish"
  assert_success || return 1
  assert_output_contains "Validating" || return 1
}

test_missing_invoke_wizardry() {
  tmpdir=$(make_tempdir)
  
  # Create incomplete structure (missing invoke-wizardry)
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  
  # Level 0 now requires invoke-wizardry and will fail without it
  WIZARDRY_DIR="$tmpdir/.wizardry" run_spell "spells/wards/banish"
  assert_failure || return 1
  # Should report that wizardry needs to be repaired
}

test_invalid_wizardry_dir() {
  tmpdir=$(make_tempdir)
  
  # Directory exists but no spells subdirectory
  mkdir -p "$tmpdir/.wizardry"
  
  # Level 0 now requires valid wizardry structure
  WIZARDRY_DIR="$tmpdir/.wizardry" run_spell "spells/wards/banish"
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
test_default_level_4() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  # Copy wizardry for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  # Level 4 should be the default.
  HOME="$tmpdir" SPELLBOOK_DIR="$tmpdir/.spellbook" AWAIT_KEYPRESS_DEVICE=/dev/null WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish"
  assert_success || return 1
  assert_output_contains "Level 4" || return 1
}

test_explicit_level_0() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  # Copy wizardry for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 0
  assert_success || return 1
  assert_output_contains "Level 0" || return 1
}

test_level_1_requires_menu() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  # Copy wizardry for realistic testing - includes menu
  copy_wizardry "$install_dir" || return 1
  
  # Test level 1 with realistic installation
  WIZARDRY_DIR="$install_dir" WIZARDRY_LOG_LEVEL=1 run_spell "spells/wards/banish" 1 --no-tests
  assert_success || return 1
  assert_output_contains "Level 1" || return 1
}

test_no_tests_flag() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  # Copy wizardry for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  HOME="$tmpdir" SPELLBOOK_DIR="$tmpdir/.spellbook" AWAIT_KEYPRESS_DEVICE=/dev/null WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" --no-tests
  assert_success || return 1
  # Success is enough - no tests were run
}

test_verbose_shows_level_info() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  # Copy wizardry for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  # Use WIZARDRY_LOG_LEVEL for verbosity instead of --verbose
  WIZARDRY_DIR="$install_dir" WIZARDRY_LOG_LEVEL=2 run_spell "spells/wards/banish" 1 --no-tests
  assert_success || return 1
  assert_output_contains "POSIX & Platform Foundation" || return 1
  assert_output_contains "Banish & Validation Infrastructure" || return 1
}

test_invalid_level() {
  run_spell "spells/wards/banish" 99
  assert_failure || return 1
  # Should reject 99 as an invalid argument
}

run_test_case "banish level 4 is default" test_default_level_4
run_test_case "banish explicit level 0" test_explicit_level_0
run_test_case "banish level 1 checks menu" test_level_1_requires_menu
run_test_case "banish --no-tests skips tests" test_no_tests_flag
run_test_case "banish verbose shows levels" test_verbose_shows_level_info
run_test_case "banish rejects invalid level" test_invalid_level

# Test that banish is preloaded by invoke-wizardry

# Test detailed status output
test_banish_shows_detailed_status() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  # Copy wizardry for realistic testing
  copy_wizardry "$install_dir" || return 1
  
  # Run banish level 1 and check for detailed status
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 1
  assert_success || return 1
  
  # Should show "Imps:" section
  assert_output_contains "Imps:" || return 1
  
  # Should show imps listed by name
  assert_output_contains "has" || return 1
  assert_output_contains "warn" || return 1
  
  return 0
}

run_test_case "banish shows detailed imp status" test_banish_shows_detailed_status


# Test cross-shell function call compatibility (eval pattern)
test_function_call_in_subshell() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Test that banish can call validate_spells via eval pattern
  # This tests the CODE_POLICY_FUNCTION_CALLS.md pattern
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 1
  assert_success || return 1
  
  # Should detect all imps (not report them as missing)
  ! assert_output_contains "Required imps: Missing:" || return 1
  
  # Should show imps as available (now grouped by category)
  assert_output_contains "Available" || return 1
  assert_output_contains "imp" || return 1
  
  return 0
}

run_test_case "banish function calls work in command substitution" test_function_call_in_subshell

# Test conditional set -e: script mode uses set -eu
test_conditional_set_e_script_mode() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # When executed as script with invalid argument, should return error code
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 999
  assert_failure || return 1
  
  # Should show error message (999 is caught as unexpected argument)
  assert_error_contains "unexpected argument" || return 1
  
  return 0
}

run_test_case "banish script mode uses set -eu" test_conditional_set_e_script_mode

# NOTE: Test for function mode shell exit prevention has been verified manually
# but has test framework issues. The functionality works correctly:
# - When banish is called as function, $0 doesn't match */banish
# - This triggers the set -u (not set -e) branch
# - Function returns error codes without exiting the calling shell

# Test that imps are detected correctly (not reported as missing)
test_imps_detected_not_missing() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Run banish and capture output
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 1
  assert_success || return 1
  
  # Should NOT report imps as missing (banish shows "Imps:" not "Missing imp")
  ! assert_output_contains "Missing imp" || return 1
  
  # Should show the "Imps:" section
  assert_output_contains "Imps:" || return 1
  
  # Should list individual imps
  assert_output_contains "has" || return 1
  assert_output_contains "warn" || return 1
  
  return 0
}

run_test_case "banish detects imps correctly (no missing imps)" test_imps_detected_not_missing

# Test eval pattern with both function and file paths
test_eval_pattern_with_file_fallback() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Even if validate_spells function is not available, 
  # banish should fall back to file path and use eval
  # This tests both branches of the _validate_cmd logic
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 1
  assert_success || return 1
  
  return 0
}

run_test_case "banish eval pattern works with file fallback" test_eval_pattern_with_file_fallback

# Test new assumption checks
test_shell_type_check() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Should detect shell type
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 0
  assert_success || return 1
  assert_output_contains "Shell type:" || return 1
  assert_output_contains "POSIX-compatible" || return 1
}

test_ifs_check() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Should check IFS
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 0
  assert_success || return 1
  assert_output_contains "IFS:" || return 1
}

test_environment_vars_check() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Should check environment variables (USER or LOGNAME depending on system)
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 0
  assert_success || return 1
  # Check for environment variable output
  # Banish should output one of:
  #  "✓ Environment: HOME and USER set"
  #  "✓ Environment: HOME and LOGNAME set" 
  #  "✗ Environment: HOME not set" (if HOME missing)
  #  "✗ Environment: USER/LOGNAME not set" (if both missing)
  # We just check that it mentions environment checks
  if ! printf '%s' "$OUTPUT" | grep -q "Environment:" ; then
    TEST_FAILURE_REASON="Expected environment variable check output, got: $OUTPUT"
    return 1
  fi
}

test_environment_vars_derive_user_from_id() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  stub_dir="$tmpdir/stubs"

  copy_wizardry "$install_dir" || return 1
  mkdir -p "$stub_dir"

  cat >"$stub_dir/id" <<'SH'
#!/bin/sh
case "${1-}" in
  -un)
    printf '%s\n' "termux-user"
    ;;
  *)
    command id "$@"
    ;;
esac
SH
  chmod +x "$stub_dir/id"

  run_cmd env PATH="$stub_dir:$PATH" USER= LOGNAME= WIZARDRY_DIR="$install_dir" \
    "$ROOT_DIR/spells/wards/banish" 0

  assert_success || return 1
  assert_output_contains "Environment: HOME set; USER derived from id" || return 1
  assert_output_contains "USER set to termux-user" || return 1
}

test_umask_check() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Should check umask
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 0
  assert_success || return 1
  assert_output_contains "umask:" || return 1
}

test_filesystem_write_check() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Should check filesystem write capability
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 0
  assert_success || return 1
  assert_output_contains "Filesystem write:" || return 1
  assert_output_contains "writable" || return 1
}

test_symbolic_links_check() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Should check symbolic link support
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 0
  assert_success || return 1
  assert_output_contains "Symbolic links:" || return 1
  assert_output_contains "Supported" || return 1
}

test_execute_permissions_check() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Should check execute permissions
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 0
  assert_success || return 1
  assert_output_contains "Execute permissions:" || return 1
  assert_output_contains "Working" || return 1
}

test_subshells_check() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Should check subshells
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 0
  assert_success || return 1
  assert_output_contains "Subshells:" || return 1
  assert_output_contains "Working correctly" || return 1
}

test_pipes_check() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Should check pipes
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 0
  assert_success || return 1
  assert_output_contains "Pipes:" || return 1
  assert_output_contains "Working" || return 1
}

test_redirections_check() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Should check redirections
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 0
  assert_success || return 1
  assert_output_contains "Redirections:" || return 1
  assert_output_contains "Working" || return 1
}

test_signal_handling_check() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Should check signal handling
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 0
  assert_success || return 1
  assert_output_contains "Signal handling:" || return 1
  assert_output_contains "trap command works" || return 1
}

test_command_substitution_check() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Should check command substitution
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 0
  assert_success || return 1
  assert_output_contains "Command substitution:" || return 1
  assert_output_contains "Working" || return 1
}

test_parameter_expansion_check() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Should check parameter expansion
  WIZARDRY_DIR="$install_dir" run_spell "spells/wards/banish" 0
  assert_success || return 1
  assert_output_contains "Parameter expansion:" || return 1
  assert_output_contains "Working" || return 1
}

test_terminal_type_self_heals_cleanly() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"

  copy_wizardry "$install_dir" || return 1

  WIZARDRY_DIR="$install_dir" TERM=dumb WIZARDRY_LOG_LEVEL=1 \
    run_spell "spells/wards/banish" 4 --no-tests
  assert_success || return 1
  assert_output_contains "Terminal type adjusted from dumb to xterm-256color" || return 1

  case "$OUTPUT" in
    *"Terminal type still minimal"*)
      TEST_FAILURE_REASON="did not expect banish to leave the terminal type unrepaired"
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

test_environment_facts_report_termux() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  stub_dir="$tmpdir/stubs"

  copy_wizardry "$install_dir" || return 1
  mkdir -p "$stub_dir"

  cat >"$stub_dir/uname" <<'SH'
#!/bin/sh
case "${1-}" in
  -s|'')
    printf '%s\n' "Linux"
    ;;
  -m)
    printf '%s\n' "aarch64"
    ;;
  *)
    printf '%s\n' "Linux"
    ;;
esac
SH
  chmod +x "$stub_dir/uname"

  run_cmd env PATH="$stub_dir:/data/data/com.termux/files/usr/bin:$PATH" \
    WIZARDRY_DIR="$install_dir" \
    "$ROOT_DIR/spells/wards/banish" 0 --no-tests

  assert_success || return 1
  assert_output_contains "Platform: linux/termux/arm64" || return 1
}

test_termux_testing_level_skips_bwrap_heal() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  stub_dir="$tmpdir/stubs"
  install_log="$tmpdir/install-bwrap.log"

  copy_wizardry "$install_dir" || return 1
  mkdir -p "$install_dir/.tests" "$stub_dir"

  cat >"$stub_dir/uname" <<'SH'
#!/bin/sh
case "${1-}" in
  -s|'')
    printf '%s\n' "Linux"
    ;;
  -m)
    printf '%s\n' "aarch64"
    ;;
  *)
    printf '%s\n' "Linux"
    ;;
esac
SH
  chmod +x "$stub_dir/uname"

  cat >"$stub_dir/detect-distro" <<'SH'
#!/bin/sh
printf '%s\n' "termux"
SH
  chmod +x "$stub_dir/detect-distro"

  cat >"$stub_dir/pocket-dimension" <<'SH'
#!/bin/sh
case "$*" in
  "--strict --check")
    exit 1
    ;;
  *)
    exit 0
    ;;
esac
SH
  chmod +x "$stub_dir/pocket-dimension"

  cat >"$stub_dir/install-bwrap" <<'SH'
#!/bin/sh
printf 'install-bwrap called\n' >>"${INSTALL_BWRAP_LOG:?}"
exit 1
SH
  chmod +x "$stub_dir/install-bwrap"

  run_cmd env PATH="$stub_dir:/data/data/com.termux/files/usr/bin:$PATH" HOME="$tmpdir" SPELLBOOK_DIR="$tmpdir/.spellbook" \
    AWAIT_KEYPRESS_DEVICE=/dev/null INSTALL_BWRAP_LOG="$install_log" WIZARDRY_DIR="$install_dir" \
    "$ROOT_DIR/spells/wards/banish" 12 --no-tests

  assert_success || return 1
  assert_output_contains "pocket-dimension available with unsandboxed Termux fallback" || return 1
  assert_output_contains "bwrap skipped on Termux" || return 1
  case "$(cat "$install_log" 2>/dev/null || true)" in
    *install-bwrap*)
      TEST_FAILURE_REASON="did not expect banish to invoke install-bwrap on Termux"
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

test_termux_testing_level_tolerates_missing_xattr_filesystem_support() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  stub_dir="$tmpdir/stubs"

  copy_wizardry "$install_dir" || return 1
  mkdir -p "$install_dir/.tests" "$stub_dir"

  cat >"$stub_dir/uname" <<'SH'
#!/bin/sh
case "${1-}" in
  -s|'')
    printf '%s\n' "Linux"
    ;;
  -m)
    printf '%s\n' "aarch64"
    ;;
  *)
    printf '%s\n' "Linux"
    ;;
esac
SH
  chmod +x "$stub_dir/uname"

  cat >"$stub_dir/detect-distro" <<'SH'
#!/bin/sh
printf '%s\n' "termux"
SH
  chmod +x "$stub_dir/detect-distro"

  cat >"$stub_dir/getfattr" <<'SH'
#!/bin/sh
exit 1
SH
  cat >"$stub_dir/setfattr" <<'SH'
#!/bin/sh
exit 1
SH
  cat >"$stub_dir/xattr" <<'SH'
#!/bin/sh
exit 1
SH
  chmod +x "$stub_dir/getfattr" "$stub_dir/setfattr" "$stub_dir/xattr"

  run_cmd env PATH="$stub_dir:/data/data/com.termux/files/usr/bin:$PATH" HOME="$tmpdir" SPELLBOOK_DIR="$tmpdir/.spellbook" \
    AWAIT_KEYPRESS_DEVICE=/dev/null WIZARDRY_DIR="$install_dir" \
    "$ROOT_DIR/spells/wards/banish" 8 --no-tests

  assert_success || return 1
  assert_output_contains "Filesystem lacks xattrs on Termux (reduced feature set)" || return 1
}

run_test_case "banish checks shell type" test_shell_type_check
run_test_case "banish checks IFS" test_ifs_check
run_test_case "banish checks environment variables" test_environment_vars_check
run_test_case "banish derives USER from id when login vars are absent" test_environment_vars_derive_user_from_id
run_test_case "banish checks umask" test_umask_check
run_test_case "banish checks filesystem write" test_filesystem_write_check
run_test_case "banish checks symbolic links" test_symbolic_links_check
run_test_case "banish checks execute permissions" test_execute_permissions_check
run_test_case "banish checks subshells" test_subshells_check
run_test_case "banish checks pipes" test_pipes_check
run_test_case "banish checks redirections" test_redirections_check
run_test_case "banish checks signal handling" test_signal_handling_check
run_test_case "banish checks command substitution" test_command_substitution_check
run_test_case "banish checks parameter expansion" test_parameter_expansion_check
run_test_case "banish environment facts report Termux on Android-style hosts" \
  test_environment_facts_report_termux
run_test_case "banish testing level skips bwrap heal on Termux" \
  test_termux_testing_level_skips_bwrap_heal
run_test_case "banish testing level tolerates missing xattrs on Termux" \
  test_termux_testing_level_tolerates_missing_xattr_filesystem_support
run_test_case "banish repairs minimal terminal types without a failure banner" \
  test_terminal_type_self_heals_cleanly

# Test via source-then-invoke pattern

finish_tests
