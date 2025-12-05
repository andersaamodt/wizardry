#!/bin/sh
# Tests for the 'trim' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_trim_removes_whitespace() {
  run_cmd sh -c "printf '  hello  ' | '$ROOT_DIR/spells/.imps/str/trim'"
  assert_success
  assert_output_contains "hello"
}

test_trim_handles_empty_input() {
  run_cmd sh -c "printf '' | '$ROOT_DIR/spells/.imps/str/trim'"
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

run_test_case "trim removes whitespace" test_trim_removes_whitespace
run_test_case "trim handles empty input" test_trim_handles_empty_input

finish_tests
