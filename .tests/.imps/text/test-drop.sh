#!/bin/sh
# Tests for the 'drop' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_drop_removes_last_lines() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/drop_test.XXXXXX")
  printf 'a\nb\nc\nd\ne\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | $ROOT_DIR/spells/.imps/text/drop 2"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "a"
  assert_output_contains "b"
  assert_output_contains "c"
  case "$OUTPUT" in
    *d*|*e*) TEST_FAILURE_REASON="output should not contain d or e"; return 1 ;;
  esac
}

test_drop_handles_empty_input() {
  run_cmd sh -c "printf '' | $ROOT_DIR/spells/.imps/text/drop 1"
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

run_test_case "drop removes last N lines" test_drop_removes_last_lines
run_test_case "drop handles empty input" test_drop_handles_empty_input

finish_tests
