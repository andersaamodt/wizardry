#!/bin/sh
# Tests for the 'norm-path' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_norm_path_normalizes() {
  run_spell spells/.imps/paths/norm-path "/tmp//test"
  assert_success
  # Should normalize double slashes
  case "$OUTPUT" in
    *//*) TEST_FAILURE_REASON="should normalize double slashes"; return 1 ;;
  esac
}

test_norm_path_handles_simple_path() {
  run_spell spells/.imps/paths/norm-path "/tmp/test"
  assert_success
  assert_output_contains "/tmp/test"
}

run_test_case "norm-path normalizes path" test_norm_path_normalizes
run_test_case "norm-path handles simple path" test_norm_path_handles_simple_path

finish_tests
