#!/bin/sh
# Tests for the 'here' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_here_outputs_directory() {
  run_spell spells/.imps/paths/here
  assert_success
  # Should output a path
  [ -d "$OUTPUT" ] || { TEST_FAILURE_REASON="should output directory"; return 1; }
}

test_here_outputs_normalized_path() {
  run_spell spells/.imps/paths/here
  assert_success
  case "$OUTPUT" in
    *///*) TEST_FAILURE_REASON="path should be normalized"; return 1 ;;
    *) return 0 ;;
  esac
}

run_test_case "here outputs current directory" test_here_outputs_directory
run_test_case "here outputs normalized path" test_here_outputs_normalized_path

finish_tests
