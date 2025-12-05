#!/bin/sh
# Tests for the 'lines' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_lines_counts() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'one\ntwo\nthree\n' > "$tmpfile"
  run_spell spells/.imps/text/lines "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "3"
}

test_lines_handles_empty_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  : > "$tmpfile"
  run_spell spells/.imps/text/lines "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "0"
}

run_test_case "lines counts correctly" test_lines_counts
run_test_case "lines handles empty file" test_lines_handles_empty_file

finish_tests
