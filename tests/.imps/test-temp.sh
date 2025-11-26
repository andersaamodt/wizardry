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

run_test_case "temp creates file" test_temp_creates_file

finish_tests
