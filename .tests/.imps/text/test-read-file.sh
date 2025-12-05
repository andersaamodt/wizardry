#!/bin/sh
# Tests for the 'read-file' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_read_file_outputs_content() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/readfile_test.XXXXXX")
  printf 'test content' > "$tmpfile"
  run_spell spells/.imps/text/read-file "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "test content"
}

test_read_file_handles_empty_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/readfile_test.XXXXXX")
  : > "$tmpfile"
  run_spell spells/.imps/text/read-file "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

run_test_case "read-file outputs content" test_read_file_outputs_content
run_test_case "read-file handles empty file" test_read_file_handles_empty_file

finish_tests
