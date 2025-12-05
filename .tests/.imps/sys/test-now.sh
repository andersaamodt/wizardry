#!/bin/sh
# Tests for the 'now' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_now_outputs_timestamp() {
  run_spell spells/.imps/sys/now
  assert_success
  # Should output a number (Unix timestamp)
  case "$OUTPUT" in
    *[!0-9]*) TEST_FAILURE_REASON="should output number"; return 1 ;;
  esac
}

test_now_returns_positive_value() {
  run_spell spells/.imps/sys/now
  assert_success
  [ "$OUTPUT" -gt 0 ] || { TEST_FAILURE_REASON="timestamp should be positive"; return 1; }
}

run_test_case "now outputs timestamp" test_now_outputs_timestamp
run_test_case "now returns positive value" test_now_returns_positive_value

finish_tests
