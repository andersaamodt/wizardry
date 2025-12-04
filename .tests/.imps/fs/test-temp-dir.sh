#!/bin/sh
# Tests for the 'temp-dir' imp

. "${0%/*}/../../test-common.sh"

test_temp_dir_creates_directory() {
  # Run temp-dir and check that the resulting directory exists (within sandbox)
  run_cmd sh -c 'd=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-dir") && [ -d "$d" ] && rmdir "$d" && printf "ok"'
  assert_success || return 1
  assert_output_contains "ok" || return 1
}

test_temp_dir_creates_unique_dirs() {
  # Run temp-dir twice and verify directories are unique
  run_cmd sh -c 'd1=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-dir") && d2=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-dir") && [ "$d1" != "$d2" ] && rmdir "$d1" "$d2" && printf "ok"'
  assert_success || return 1
  assert_output_contains "ok" || return 1
}

test_temp_dir_with_prefix() {
  # Check that custom prefix is used in the path
  run_cmd sh -c 'd=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-dir" myprefix) && case "$d" in */myprefix.*) rmdir "$d"; printf "ok";; *) printf "bad: %s" "$d"; exit 1;; esac'
  assert_success || return 1
  assert_output_contains "ok" || return 1
}

test_temp_dir_default_prefix() {
  # Check that default prefix 'wizardry' is used
  run_cmd sh -c 'd=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-dir") && case "$d" in */wizardry.*) rmdir "$d"; printf "ok";; *) printf "bad: %s" "$d"; exit 1;; esac'
  assert_success || return 1
  assert_output_contains "ok" || return 1
}

run_test_case "temp-dir creates directory" test_temp_dir_creates_directory
run_test_case "temp-dir creates unique directories" test_temp_dir_creates_unique_dirs
run_test_case "temp-dir with custom prefix" test_temp_dir_with_prefix
run_test_case "temp-dir uses default prefix" test_temp_dir_default_prefix

finish_tests
