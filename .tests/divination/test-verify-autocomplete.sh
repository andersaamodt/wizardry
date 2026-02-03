#!/bin/sh
# Tests for verify-autocomplete spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_verify_autocomplete_exists() {
  [ -x "$ROOT_DIR/spells/divination/verify-autocomplete" ]
}

test_verify_autocomplete_help() {
  run_spell spells/divination/verify-autocomplete --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "verify-autocomplete" || return 1
}

test_verify_autocomplete_requires_bash() {
  # When run with sh (not bash), should error
  output=$(sh "$ROOT_DIR/spells/divination/verify-autocomplete" 2>&1 || true)
  case "$output" in
    *"requires bash"*) return 0 ;;
    *) 
      TEST_FAILURE_REASON="Expected 'requires bash' error, got: $output"
      return 1
      ;;
  esac
}

test_verify_autocomplete_detects_missing_wizardry() {
  # When wizardry not in PATH, should detect it
  # Use env -i to clear PATH
  output=$(env -i PATH="/usr/bin:/bin" bash "$ROOT_DIR/spells/divination/verify-autocomplete" 2>&1 || true)
  case "$output" in
    *"not in PATH"*) return 0 ;;
    *)
      TEST_FAILURE_REASON="Expected 'not in PATH' error, got: $output"
      return 1
      ;;
  esac
}

run_test_case "verify-autocomplete exists" test_verify_autocomplete_exists
run_test_case "verify-autocomplete --help" test_verify_autocomplete_help
run_test_case "verify-autocomplete requires bash" test_verify_autocomplete_requires_bash
run_test_case "verify-autocomplete detects missing wizardry" test_verify_autocomplete_detects_missing_wizardry
finish_tests
