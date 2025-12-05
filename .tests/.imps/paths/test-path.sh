#!/bin/sh
# Tests for the 'path' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_path_normalizes() {
  run_spell spells/.imps/paths/path "./test"
  assert_success
  # Should output an absolute path
  case "$OUTPUT" in
    /*) return 0 ;;
    *) TEST_FAILURE_REASON="should output absolute path"; return 1 ;;
  esac
}

test_path_handles_absolute_input() {
  run_spell spells/.imps/paths/path "/tmp/test"
  assert_success
  assert_output_contains "/tmp/test"
}

run_test_case "path normalizes relative path" test_path_normalizes
run_test_case "path handles absolute input" test_path_handles_absolute_input

finish_tests
