#!/bin/sh
# Tests for the 'declare-globals' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_declare_globals_is_sourceable() {
  # declare-globals should be sourceable without error
  run_cmd sh -c ". '$ROOT_DIR/spells/.imps/declare-globals'"
  assert_success
}

test_declare_globals_allows_set_u() {
  # After sourcing, scripts with set -u should not fail on declared globals
  run_cmd sh -c "set -u; . '$ROOT_DIR/spells/.imps/declare-globals'; : \"\$WIZARDRY_DIR\""
  assert_success
}

test_declare_globals_sets_empty_defaults() {
  # Globals should default to empty string, not cause unbound variable error
  run_cmd sh -c ". '$ROOT_DIR/spells/.imps/declare-globals'; printf '%s' \"\$WIZARDRY_DIR\""
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected empty default"; return 1; }
}

test_declare_globals_preserves_existing_values() {
  # If a global is already set, declare-globals should preserve it
  run_cmd sh -c "WIZARDRY_DIR=/test/path; . '$ROOT_DIR/spells/.imps/declare-globals'; printf '%s' \"\$WIZARDRY_DIR\""
  assert_success
  [ "$OUTPUT" = "/test/path" ] || { TEST_FAILURE_REASON="expected /test/path but got $OUTPUT"; return 1; }
}

run_test_case "declare-globals is sourceable" test_declare_globals_is_sourceable
run_test_case "declare-globals allows set -u" test_declare_globals_allows_set_u
run_test_case "declare-globals sets empty defaults" test_declare_globals_sets_empty_defaults
run_test_case "declare-globals preserves existing values" test_declare_globals_preserves_existing_values

finish_tests
