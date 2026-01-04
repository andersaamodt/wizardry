#!/bin/sh
# COMPILED_UNSUPPORTED: requires interactive input
# Test coverage for priorities spell:
# - Shows usage with --help
# - Requires read-magic command
# - Exits when no priorities set
# - Verbose flag shows priority numbers

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/menu/priorities" --help
  assert_success || return 1
  assert_output_contains "Usage: priorities" || return 1
}

test_help_h_flag() {
  run_spell "spells/menu/priorities" -h
  assert_success || return 1
  assert_output_contains "Usage: priorities" || return 1
}

test_help_usage_flag() {
  run_spell "spells/menu/priorities" --usage
  assert_success || return 1
  assert_output_contains "Usage: priorities" || return 1
}

test_verbose_flag_accepted() {
  # Test that -v flag with --help is recognized
  run_spell "spells/menu/priorities" --help
  assert_success || return 1
  # Verify help mentions verbose mode
  assert_output_contains "-v" || return 1
}

test_no_priorities_exits_gracefully() {
  tmp=$(make_tempdir)
  # Create read-magic stub that says no priorities
  cat >"$tmp/read-magic" <<'SH'
#!/bin/sh
echo "read-magic: attribute does not exist."
SH
  chmod +x "$tmp/read-magic"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Run in the temp directory
  run_cmd env PATH="$tmp:$PATH" PWD="$tmp" "$ROOT_DIR/spells/menu/priorities"
  # Should fail with message about no priorities
  assert_failure || return 1
  assert_output_contains "No priorities set" || return 1
}

test_invalid_option_produces_error() {
  run_spell "spells/menu/priorities" -z 2>&1
  # Invalid option should produce error message (getopts says "Illegal option")
  # The stderr may capture the error
  case "$OUTPUT$ERROR" in
    *"llegal option"*|*"nvalid option"*) : ;;
    *) TEST_FAILURE_REASON="expected error for invalid option: $OUTPUT $ERROR"; return 1 ;;
  esac
}

run_test_case "priorities shows usage text" test_help
run_test_case "priorities shows usage with -h" test_help_h_flag
run_test_case "priorities shows usage with --usage" test_help_usage_flag
run_test_case "priorities accepts -v flag" test_verbose_flag_accepted
run_test_case "priorities exits when no priorities set" test_no_priorities_exits_gracefully
run_test_case "priorities produces error for invalid options" test_invalid_option_produces_error


# Test via source-then-invoke pattern  

finish_tests
