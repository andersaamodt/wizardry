#!/bin/sh
# Tests for the 'temp-dir' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_temp_dir_creates_directory() {
  skip-if-compiled || return $?
  # Run temp-dir and check that the resulting directory exists (within sandbox)
  _run_cmd sh -c 'd=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-dir") && [ -d "$d" ] && rmdir "$d" && printf "ok"'
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_temp_dir_creates_unique_dirs() {
  skip-if-compiled || return $?
  # Run temp-dir twice and verify directories are unique
  _run_cmd sh -c 'd1=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-dir") && d2=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-dir") && [ "$d1" != "$d2" ] && rmdir "$d1" "$d2" && printf "ok"'
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_temp_dir_with_prefix() {
  skip-if-compiled || return $?
  # Check that custom prefix is used in the path
  _run_cmd sh -c 'd=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-dir" myprefix) && case "$d" in */myprefix.*) rmdir "$d"; printf "ok";; *) printf "bad: %s" "$d"; exit 1;; esac'
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_temp_dir_default_prefix() {
  skip-if-compiled || return $?
  # Check that default prefix 'wizardry' is used
  _run_cmd sh -c 'd=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-dir") && case "$d" in */wizardry.*) rmdir "$d"; printf "ok";; *) printf "bad: %s" "$d"; exit 1;; esac'
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

_run_test_case "temp-dir creates directory" test_temp_dir_creates_directory
_run_test_case "temp-dir creates unique directories" test_temp_dir_creates_unique_dirs
_run_test_case "temp-dir with custom prefix" test_temp_dir_with_prefix
_run_test_case "temp-dir uses default prefix" test_temp_dir_default_prefix

_finish_tests
