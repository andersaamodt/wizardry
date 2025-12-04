#!/bin/sh
# Tests for the 'cleanup-dir' imp

. "${0%/*}/../../test-common.sh"

test_cleanup_dir_removes_existing_directory() {
  # Create a directory and verify cleanup removes it
  run_cmd sh -c 'd=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-dir" testclean) && "'"$ROOT_DIR"'/spells/.imps/fs/cleanup-dir" "$d" && [ ! -d "$d" ] && printf "ok"'
  assert_success || return 1
  assert_output_contains "ok" || return 1
}

test_cleanup_dir_silent_on_missing() {
  # Cleanup should succeed even if directory doesn't exist
  run_cmd sh -c '"'"$ROOT_DIR"'/spells/.imps/fs/cleanup-dir" "/nonexistent/dir/path" && printf "ok"'
  assert_success || return 1
  assert_output_contains "ok" || return 1
}

test_cleanup_dir_silent_on_empty_arg() {
  # Cleanup should succeed with empty argument
  run_cmd sh -c '"'"$ROOT_DIR"'/spells/.imps/fs/cleanup-dir" "" && printf "ok"'
  assert_success || return 1
  assert_output_contains "ok" || return 1
}

run_test_case "cleanup-dir removes existing directory" test_cleanup_dir_removes_existing_directory
run_test_case "cleanup-dir silent on missing directory" test_cleanup_dir_silent_on_missing
run_test_case "cleanup-dir silent on empty arg" test_cleanup_dir_silent_on_empty_arg

finish_tests
