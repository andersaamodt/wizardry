#!/bin/sh
# Tests for the 'write-file' imp

. "${0%/*}/../test_common.sh"

test_write_file_creates_file() {
  tmpfile="$WIZARDRY_TMPDIR/writefile_test_$$"
  run_cmd sh -c "printf 'test content' | '$ROOT_DIR/spells/.imps/write-file' '$tmpfile'"
  assert_success
  content=$(cat "$tmpfile" 2>/dev/null)
  rm -f "$tmpfile"
  [ "$content" = "test content" ] || { TEST_FAILURE_REASON="file content mismatch"; return 1; }
}

run_test_case "write-file creates file" test_write_file_creates_file

finish_tests
