#!/bin/sh
# Tests for the 'temp' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

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
