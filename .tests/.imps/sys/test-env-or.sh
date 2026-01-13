#!/bin/sh
# Tests for the 'env-or' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_env_or_returns_set_var() {
  export TEST_VAR_SET="myvalue"
  run_spell spells/.imps/sys/env-or TEST_VAR_SET "fallback"
  assert_success
  assert_output_contains "myvalue"
  unset TEST_VAR_SET
}

test_env_or_returns_fallback_unset() {
  skip-if-compiled || return $?
  unset TEST_VAR_UNSET 2>/dev/null || true
  run_spell spells/.imps/sys/env-or TEST_VAR_UNSET "fallback"
  assert_success
  assert_output_contains "fallback"
}

test_env_or_returns_fallback_empty() {
  export TEST_VAR_EMPTY=""
  run_spell spells/.imps/sys/env-or TEST_VAR_EMPTY "fallback"
  assert_success
  assert_output_contains "fallback"
  unset TEST_VAR_EMPTY
}

test_env_or_home_path() {
  # Test with HOME which should be set
  run_spell spells/.imps/sys/env-or HOME "/default/home"
  assert_success
  # Output should contain HOME value (not the default)
  case "$OUTPUT" in
    /default/home) TEST_FAILURE_REASON="should return HOME value, not fallback"; return 1 ;;
    *) return 0 ;;
  esac
}

test_env_or_invalid_varname() {
  skip-if-compiled || return $?
  # Invalid var names should safely return fallback
  run_spell spells/.imps/sys/env-or "invalid;var" "safe_fallback"
  assert_success
  assert_output_contains "safe_fallback"
}

run_test_case "env-or returns value when var is set" test_env_or_returns_set_var
run_test_case "env-or returns fallback when var is unset" test_env_or_returns_fallback_unset
run_test_case "env-or returns fallback when var is empty" test_env_or_returns_fallback_empty
run_test_case "env-or works with HOME variable" test_env_or_home_path
run_test_case "env-or handles invalid variable names safely" test_env_or_invalid_varname

finish_tests
