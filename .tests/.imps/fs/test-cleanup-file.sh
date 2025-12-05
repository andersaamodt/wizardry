#!/bin/sh
# Tests for the 'cleanup-file' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_cleanup_file_removes_existing_file() {
  # Create a file and verify cleanup removes it
  run_cmd sh -c 'f=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-file" testclean) && "'"$ROOT_DIR"'/spells/.imps/fs/cleanup-file" "$f" && [ ! -f "$f" ] && printf "ok"'
  assert_success || return 1
  assert_output_contains "ok" || return 1
}

test_cleanup_file_silent_on_missing() {
  # Cleanup should succeed even if file doesn't exist
  run_cmd sh -c '"'"$ROOT_DIR"'/spells/.imps/fs/cleanup-file" "/nonexistent/file/path" && printf "ok"'
  assert_success || return 1
  assert_output_contains "ok" || return 1
}

test_cleanup_file_silent_on_empty_arg() {
  # Cleanup should succeed with empty argument
  run_cmd sh -c '"'"$ROOT_DIR"'/spells/.imps/fs/cleanup-file" "" && printf "ok"'
  assert_success || return 1
  assert_output_contains "ok" || return 1
}

run_test_case "cleanup-file removes existing file" test_cleanup_file_removes_existing_file
run_test_case "cleanup-file silent on missing file" test_cleanup_file_silent_on_missing
run_test_case "cleanup-file silent on empty arg" test_cleanup_file_silent_on_empty_arg

finish_tests
