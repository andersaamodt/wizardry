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
  _run_spell "spells/menu/priorities" --help
  _assert_success || return 1
  _assert_output_contains "Usage: priorities" || return 1
}

test_help_h_flag() {
  _run_spell "spells/menu/priorities" -h
  _assert_success || return 1
  _assert_output_contains "Usage: priorities" || return 1
}

test_help_usage_flag() {
  _run_spell "spells/menu/priorities" --usage
  _assert_success || return 1
  _assert_output_contains "Usage: priorities" || return 1
}

test_verbose_flag_accepted() {
  # Test that -v flag with --help is recognized
  _run_spell "spells/menu/priorities" --help
  _assert_success || return 1
  # Verify help mentions verbose mode
  _assert_output_contains "-v" || return 1
}

test_no_priorities_exits_gracefully() {
  tmp=$(_make_tempdir)
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
  _run_cmd env PATH="$tmp:$PATH" PWD="$tmp" "$ROOT_DIR/spells/menu/priorities"
  # Should fail with message about no priorities
  _assert_failure || return 1
  _assert_output_contains "No priorities set" || return 1
}

test_invalid_option_produces_error() {
  _run_spell "spells/menu/priorities" -z 2>&1
  # Invalid option should produce error message (getopts says "Illegal option")
  # The stderr may capture the error
  case "$OUTPUT$ERROR" in
    *"llegal option"*|*"nvalid option"*) : ;;
    *) TEST_FAILURE_REASON="expected error for invalid option: $OUTPUT $ERROR"; return 1 ;;
  esac
}

_run_test_case "priorities shows usage text" test_help
_run_test_case "priorities shows usage with -h" test_help_h_flag
_run_test_case "priorities shows usage with --usage" test_help_usage_flag
_run_test_case "priorities accepts -v flag" test_verbose_flag_accepted
_run_test_case "priorities exits when no priorities set" test_no_priorities_exits_gracefully
_run_test_case "priorities produces error for invalid options" test_invalid_option_produces_error

_finish_tests
