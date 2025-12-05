#!/bin/sh
# Tests for the 'read-file' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_read_file_outputs_content() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/readfile_test.XXXXXX")
  printf 'test content' > "$tmpfile"
  _run_spell spells/.imps/text/read-file "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
  _assert_output_contains "test content"
}

test_read_file_handles_empty_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/readfile_test.XXXXXX")
  : > "$tmpfile"
  _run_spell spells/.imps/text/read-file "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

_run_test_case "read-file outputs content" test_read_file_outputs_content
_run_test_case "read-file handles empty file" test_read_file_handles_empty_file

_finish_tests
