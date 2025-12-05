#!/bin/sh
# Tests for the 'each' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_each_runs_for_lines() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'a\nb\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | '$ROOT_DIR/spells/.imps/text/each' echo 'item:'"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "item: a"
  assert_output_contains "item: b"
}

test_each_handles_empty_input() {
  run_cmd sh -c "printf '' | '$ROOT_DIR/spells/.imps/text/each' echo 'item:'"
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

run_test_case "each runs for each line" test_each_runs_for_lines
run_test_case "each handles empty input" test_each_handles_empty_input

finish_tests
