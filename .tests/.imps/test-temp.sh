#!/bin/sh
# Tests for the 'temp' imp

. "${0%/*}/../test-common.sh"

test_temp_creates_file() {
  tmpfile=$("$ROOT_DIR/spells/.imps/temp")
  if [ -f "$tmpfile" ]; then
    rm -f "$tmpfile"
    return 0
  fi
  TEST_FAILURE_REASON="temp file should exist at $tmpfile"
  return 1
}

test_temp_creates_unique_files() {
  tmpfile1=$("$ROOT_DIR/spells/.imps/temp")
  tmpfile2=$("$ROOT_DIR/spells/.imps/temp")
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
