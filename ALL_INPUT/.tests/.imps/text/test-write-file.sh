#!/bin/sh
# Tests for the 'write-file' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_write_file_creates_file() {
  skip-if-compiled || return $?
  tmpfile="$WIZARDRY_TMPDIR/writefile_test_$$"
  _run_cmd sh -c "printf 'test content' | '$ROOT_DIR/spells/.imps/text/write-file' '$tmpfile'"
  _assert_success
  content=$(cat "$tmpfile" 2>/dev/null)
  rm -f "$tmpfile"
  [ "$content" = "test content" ] || { TEST_FAILURE_REASON="file content mismatch"; return 1; }
}

test_write_file_overwrites_existing() {
  skip-if-compiled || return $?
  tmpfile="$WIZARDRY_TMPDIR/writefile_test_$$"
  printf 'old content' > "$tmpfile"
  _run_cmd sh -c "printf 'new content' | '$ROOT_DIR/spells/.imps/text/write-file' '$tmpfile'"
  _assert_success
  content=$(cat "$tmpfile" 2>/dev/null)
  rm -f "$tmpfile"
  [ "$content" = "new content" ] || { TEST_FAILURE_REASON="file should be overwritten"; return 1; }
}

_run_test_case "write-file creates file" test_write_file_creates_file
_run_test_case "write-file overwrites existing" test_write_file_overwrites_existing

_finish_tests
