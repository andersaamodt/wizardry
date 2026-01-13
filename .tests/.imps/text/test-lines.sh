#!/bin/sh
# Tests for the 'lines' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

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
