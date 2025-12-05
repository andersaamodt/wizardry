#!/bin/sh
# Tests for the 'declare-globals' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_declare_globals_is_sourceable() {
  # declare-globals should be sourceable without error
  _run_cmd sh -c ". '$ROOT_DIR/spells/.imps/declare-globals'"
  _assert_success
}

test_declare_globals_allows_set_u() {
  # After sourcing and calling the function, scripts with set -u should not fail on declared globals
  _run_cmd sh -c "set -u; . '$ROOT_DIR/spells/.imps/declare-globals'; _declare_globals; : \"\$WIZARDRY_DIR\""
  _assert_success
}

test_declare_globals_sets_empty_defaults() {
  # Globals should default to empty string, not cause unbound variable error
  _run_cmd sh -c ". '$ROOT_DIR/spells/.imps/declare-globals'; _declare_globals; printf '%s' \"\$WIZARDRY_DIR\""
  _assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected empty default"; return 1; }
}

test_declare_globals_preserves_existing_values() {
  # If a global is already set, declare-globals should preserve it
  _run_cmd sh -c "WIZARDRY_DIR=/test/path; . '$ROOT_DIR/spells/.imps/declare-globals'; _declare_globals; printf '%s' \"\$WIZARDRY_DIR\""
  _assert_success
  [ "$OUTPUT" = "/test/path" ] || { TEST_FAILURE_REASON="expected /test/path but got $OUTPUT"; return 1; }
}

_run_test_case "declare-globals is sourceable" test_declare_globals_is_sourceable
_run_test_case "declare-globals allows set -u" test_declare_globals_allows_set_u
_run_test_case "declare-globals sets empty defaults" test_declare_globals_sets_empty_defaults
_run_test_case "declare-globals preserves existing values" test_declare_globals_preserves_existing_values

_finish_tests
