#!/bin/sh
# Tests for the 'temp-file' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_temp_file_creates_file() {
  skip-if-compiled || return $?
  # Run temp-file and check that the resulting file exists (within sandbox)
  _run_cmd sh -c 'f=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-file") && [ -f "$f" ] && rm -f "$f" && printf "ok"'
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_temp_file_creates_unique_files() {
  skip-if-compiled || return $?
  # Run temp-file twice and verify files are unique
  _run_cmd sh -c 'f1=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-file") && f2=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-file") && [ "$f1" != "$f2" ] && rm -f "$f1" "$f2" && printf "ok"'
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_temp_file_with_prefix() {
  skip-if-compiled || return $?
  # Check that custom prefix is used in the path
  _run_cmd sh -c 'f=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-file" myprefix) && case "$f" in */myprefix.*) rm -f "$f"; printf "ok";; *) printf "bad: %s" "$f"; exit 1;; esac'
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_temp_file_default_prefix() {
  skip-if-compiled || return $?
  # Check that default prefix 'wizardry' is used
  _run_cmd sh -c 'f=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-file") && case "$f" in */wizardry.*) rm -f "$f"; printf "ok";; *) printf "bad: %s" "$f"; exit 1;; esac'
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

_run_test_case "temp-file creates file" test_temp_file_creates_file
_run_test_case "temp-file creates unique files" test_temp_file_creates_unique_files
_run_test_case "temp-file with custom prefix" test_temp_file_with_prefix
_run_test_case "temp-file uses default prefix" test_temp_file_default_prefix

_finish_tests
