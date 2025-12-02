#!/bin/sh
# Tests for the 'declare-globals' imp

. "${0%/*}/../test-common.sh"

test_declare_globals_is_sourceable() {
  # Verify the file can be sourced without errors
  run_cmd sh -c '. "$1"' _ "$ROOT_DIR/spells/.imps/declare-globals"
  assert_success
}

test_declare_globals_sets_empty_defaults() {
  # After sourcing, a sample WIZARDRY_* variable should exist (even if empty)
  run_cmd sh -c '
    . "$1"
    # If variable is declared (even empty), this exits 0 with set -u
    set -u
    : "${WIZARDRY_DIR}"
  ' _ "$ROOT_DIR/spells/.imps/declare-globals"
  assert_success
}

test_undeclared_global_fails_with_set_u() {
  # An undeclared variable should cause failure with set -u
  run_cmd sh -c '
    . "$1"
    set -u
    # This should fail because WIZARDRY_FAKE_UNDECLARED is not declared
    echo "${WIZARDRY_FAKE_UNDECLARED}"
  ' _ "$ROOT_DIR/spells/.imps/declare-globals"
  assert_failure
}

run_test_case "declare-globals is sourceable" test_declare_globals_is_sourceable
run_test_case "declare-globals sets empty defaults" test_declare_globals_sets_empty_defaults
run_test_case "undeclared global fails with set -u" test_undeclared_global_fails_with_set_u

finish_tests
