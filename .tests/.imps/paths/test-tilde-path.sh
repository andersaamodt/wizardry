#!/bin/sh
# Tests for the 'tilde-path' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_tilde_path_converts_home() {
  skip-if-compiled || return $?
  run_cmd sh -c "
    HOME='/home/testuser'
    export HOME
    '$ROOT_DIR/spells/.imps/paths/tilde-path' '/home/testuser/Documents'
  "
  assert_success
  assert_output_contains "~/Documents"
  [ "$OUTPUT" = "~/Documents" ] || { TEST_FAILURE_REASON="expected '~/Documents', got '$OUTPUT'"; return 1; }
}

test_tilde_path_converts_exact_home() {
  skip-if-compiled || return $?
  run_cmd sh -c "
    HOME='/home/testuser'
    export HOME
    '$ROOT_DIR/spells/.imps/paths/tilde-path' '/home/testuser'
  "
  assert_success
  assert_output_contains "~"
  [ "$OUTPUT" = "~" ] || { TEST_FAILURE_REASON="expected '~', got '$OUTPUT'"; return 1; }
}

test_tilde_path_preserves_non_home() {
  skip-if-compiled || return $?
  run_cmd sh -c "
    HOME='/home/testuser'
    export HOME
    '$ROOT_DIR/spells/.imps/paths/tilde-path' '/opt/something'
  "
  assert_success
  assert_output_contains "/opt/something"
  [ "$OUTPUT" = "/opt/something" ] || { TEST_FAILURE_REASON="expected '/opt/something', got '$OUTPUT'"; return 1; }
}

test_tilde_path_handles_no_home() {
  skip-if-compiled || return $?
  run_cmd sh -c "
    HOME=''
    export HOME
    '$ROOT_DIR/spells/.imps/paths/tilde-path' '/home/testuser/Documents'
  "
  assert_success
  assert_output_contains "/home/testuser/Documents"
  [ "$OUTPUT" = "/home/testuser/Documents" ] || { TEST_FAILURE_REASON="expected '/home/testuser/Documents', got '$OUTPUT'"; return 1; }
}

test_tilde_path_handles_nested_path() {
  skip-if-compiled || return $?
  run_cmd sh -c "
    HOME='/home/testuser'
    export HOME
    '$ROOT_DIR/spells/.imps/paths/tilde-path' '/home/testuser/.spellbook/custom'
  "
  assert_success
  assert_output_contains "~/.spellbook/custom"
  [ "$OUTPUT" = "~/.spellbook/custom" ] || { TEST_FAILURE_REASON="expected '~/.spellbook/custom', got '$OUTPUT'"; return 1; }
}

test_tilde_path_requires_argument() {
  skip-if-compiled || return $?
  run_spell spells/.imps/paths/tilde-path
  assert_failure || return 1
  assert_error_contains "exactly one argument required" || return 1
}

run_test_case "tilde-path converts HOME path" test_tilde_path_converts_home
run_test_case "tilde-path converts exact HOME" test_tilde_path_converts_exact_home
run_test_case "tilde-path preserves non-HOME paths" test_tilde_path_preserves_non_home
run_test_case "tilde-path handles no HOME" test_tilde_path_handles_no_home
run_test_case "tilde-path handles nested paths" test_tilde_path_handles_nested_path
run_test_case "tilde-path requires argument" test_tilde_path_requires_argument

finish_tests
