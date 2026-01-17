#!/bin/sh
# Tests for the 'wizardry-globals' imp

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
  skip-if-compiled || return $?
  # wizardry-globals should be sourceable without error
  run_cmd sh -c ". '$ROOT_DIR/spells/.imps/wizardry-globals'"
  assert_success
}

test_declare_globals_allows_set_u() {
  skip-if-compiled || return $?
  # After sourcing and calling the function, scripts with set -u should not fail on declared globals
  run_cmd sh -c "set -u; . '$ROOT_DIR/spells/.imps/wizardry-globals'; declare_globals; : \"\$WIZARDRY_DIR\""
  assert_success
}

test_declare_globals_sets_empty_defaults() {
  # Globals should default to empty string, not cause unbound variable error
  # Unset WIZARDRY_DIR since test-bootstrap sets it
  run_cmd sh -c "unset WIZARDRY_DIR; . '$ROOT_DIR/spells/.imps/wizardry-globals'; declare_globals; printf '%s' \"\$WIZARDRY_DIR\""
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected empty default"; return 1; }
}

test_declare_globals_preserves_existing_values() {
  skip-if-compiled || return $?
  # If a global is already set, wizardry-globals should preserve it
  run_cmd sh -c "WIZARDRY_DIR=/test/path; . '$ROOT_DIR/spells/.imps/wizardry-globals'; declare_globals; printf '%s' \"\$WIZARDRY_DIR\""
  assert_success
  [ "$OUTPUT" = "/test/path" ] || { TEST_FAILURE_REASON="expected /test/path but got $OUTPUT"; return 1; }
}

run_test_case "wizardry-globals is sourceable" test_declare_globals_is_sourceable
run_test_case "wizardry-globals allows set -u" test_declare_globals_allows_set_u
run_test_case "wizardry-globals sets empty defaults" test_declare_globals_sets_empty_defaults
run_test_case "wizardry-globals preserves existing values" test_declare_globals_preserves_existing_values

finish_tests
