#!/bin/sh
# Tests for the 'write-file' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_write_file_creates_file() {
  tmpfile="$WIZARDRY_TMPDIR/writefile_test_$$"
  run_cmd sh -c "printf 'test content' | '$ROOT_DIR/spells/.imps/text/write-file' '$tmpfile'"
  assert_success
  content=$(cat "$tmpfile" 2>/dev/null)
  rm -f "$tmpfile"
  [ "$content" = "test content" ] || { TEST_FAILURE_REASON="file content mismatch"; return 1; }
}

test_write_file_overwrites_existing() {
  tmpfile="$WIZARDRY_TMPDIR/writefile_test_$$"
  printf 'old content' > "$tmpfile"
  run_cmd sh -c "printf 'new content' | '$ROOT_DIR/spells/.imps/text/write-file' '$tmpfile'"
  assert_success
  content=$(cat "$tmpfile" 2>/dev/null)
  rm -f "$tmpfile"
  [ "$content" = "new content" ] || { TEST_FAILURE_REASON="file should be overwritten"; return 1; }
}

run_test_case "write-file creates file" test_write_file_creates_file
run_test_case "write-file overwrites existing" test_write_file_overwrites_existing

finish_tests
