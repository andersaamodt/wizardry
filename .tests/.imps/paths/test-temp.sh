#!/bin/sh
# Tests for the 'temp' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_temp_creates_file() {
  tmpfile=$("$ROOT_DIR/spells/.imps/paths/temp")
  if [ -f "$tmpfile" ]; then
    rm -f "$tmpfile"
    return 0
  fi
  TEST_FAILURE_REASON="temp file should exist at $tmpfile"
  return 1
}

test_temp_creates_unique_files() {
  tmpfile1=$("$ROOT_DIR/spells/.imps/paths/temp")
  tmpfile2=$("$ROOT_DIR/spells/.imps/paths/temp")
  result=0
  if [ "$tmpfile1" = "$tmpfile2" ]; then
    TEST_FAILURE_REASON="temp files should be unique"
    result=1
  fi
  rm -f "$tmpfile1" "$tmpfile2"
  return $result
}

run_test_case "temp creates file" test_temp_creates_file
run_test_case "temp creates unique files" test_temp_creates_unique_files

finish_tests
