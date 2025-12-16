#!/bin/sh
# Tests for the 'cleanup-dir' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_cleanup_dir_removes_existing_directory() {
  # Create a directory and verify cleanup removes it
  _run_cmd sh -c 'd=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-dir" testclean) && "'"$ROOT_DIR"'/spells/.imps/fs/cleanup-dir" "$d" && [ ! -d "$d" ] && printf "ok"'
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_cleanup_dir_silent_on_missing() {
  # Cleanup should succeed even if directory doesn't exist
  _run_cmd sh -c '"'"$ROOT_DIR"'/spells/.imps/fs/cleanup-dir" "/nonexistent/dir/path" && printf "ok"'
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_cleanup_dir_silent_on_empty_arg() {
  # Cleanup should succeed with empty argument
  _run_cmd sh -c '"'"$ROOT_DIR"'/spells/.imps/fs/cleanup-dir" "" && printf "ok"'
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

_run_test_case "cleanup-dir removes existing directory" test_cleanup_dir_removes_existing_directory
_run_test_case "cleanup-dir silent on missing directory" test_cleanup_dir_silent_on_missing
_run_test_case "cleanup-dir silent on empty arg" test_cleanup_dir_silent_on_empty_arg

_finish_tests
