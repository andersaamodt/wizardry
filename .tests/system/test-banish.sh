#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/system/banish" --help
  _assert_success || return 1
  _assert_output_contains "Usage:" || return 1
  _assert_output_contains "banish" || return 1
}

test_basic_execution() {
  tmpdir=$(_make_tempdir)
  
  # Create minimal wizardry structure
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  touch "$tmpdir/.wizardry/spells/.imps/sys/invoke-wizardry"
  
  # Run banish with explicit WIZARDRY_DIR and verbose to get output
  WIZARDRY_DIR="$tmpdir/.wizardry" WIZARDRY_LOG_LEVEL=1 _run_spell "spells/system/banish"
  _assert_success || return 1
  _assert_output_contains "Banish complete" || return 1
}

test_auto_detect_from_home() {
  tmpdir=$(_make_tempdir)
  
  # Create structure at HOME/.wizardry
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  touch "$tmpdir/.wizardry/spells/.imps/sys/invoke-wizardry"
  
  # Run without WIZARDRY_DIR set, should auto-detect from HOME
  HOME="$tmpdir" _run_spell "spells/system/banish"
  _assert_success || return 1
}

test_verbose_mode() {
  tmpdir=$(_make_tempdir)
  
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  touch "$tmpdir/.wizardry/spells/.imps/sys/invoke-wizardry"
  
  WIZARDRY_DIR="$tmpdir/.wizardry" _run_spell "spells/system/banish" --verbose
  _assert_success || return 1
  # Verbose mode now uses checklist format with ✓ instead of DEBUG:
  _assert_output_contains "✓" || return 1
  _assert_output_contains "Configuring WIZARDRY_DIR:" || return 1
}

test_non_verbose_has_output() {
  tmpdir=$(_make_tempdir)
  
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  touch "$tmpdir/.wizardry/spells/.imps/sys/invoke-wizardry"
  
  # Non-verbose mode should now have output (this is the fix)
  WIZARDRY_DIR="$tmpdir/.wizardry" _run_spell "spells/system/banish"
  _assert_success || return 1
  _assert_output_contains "Environment prepared" || return 1
  _assert_output_contains "Banish complete" || return 1
}

test_custom_wizardry_dir() {
  tmpdir=$(_make_tempdir)
  
  mkdir -p "$tmpdir/custom/spells/.imps/sys"
  touch "$tmpdir/custom/spells/.imps/sys/invoke-wizardry"
  
  WIZARDRY_LOG_LEVEL=1 _run_spell "spells/system/banish" --wizardry-dir "$tmpdir/custom"
  _assert_success || return 1
  _assert_output_contains "Banish complete" || return 1
}

test_missing_invoke_wizardry() {
  tmpdir=$(_make_tempdir)
  
  # Create incomplete structure (missing invoke-wizardry)
  mkdir -p "$tmpdir/.wizardry/spells/.imps/sys"
  
  WIZARDRY_DIR="$tmpdir/.wizardry" _run_spell "spells/system/banish"
  _assert_failure || return 1
  _assert_error_contains "invoke-wizardry not found" || return 1
}

test_invalid_wizardry_dir() {
  tmpdir=$(_make_tempdir)
  
  # Directory exists but no spells subdirectory
  mkdir -p "$tmpdir/.wizardry"
  
  WIZARDRY_DIR="$tmpdir/.wizardry" _run_spell "spells/system/banish"
  _assert_failure || return 1
  _assert_error_contains "does not contain spells directory" || return 1
}

_run_test_case "banish prints help" test_help
_run_test_case "banish basic execution" test_basic_execution
_run_test_case "banish auto-detects from HOME" test_auto_detect_from_home
_run_test_case "banish verbose mode" test_verbose_mode
_run_test_case "banish non-verbose has output" test_non_verbose_has_output
_run_test_case "banish custom wizardry-dir" test_custom_wizardry_dir
_run_test_case "banish fails without invoke-wizardry" test_missing_invoke_wizardry
_run_test_case "banish fails with invalid dir" test_invalid_wizardry_dir

_finish_tests
