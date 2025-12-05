#!/bin/sh
# Tests for the 'test-find-repo-root' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_test_find_repo_root_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test/test-find-repo-root" ]
}

test_test_find_repo_root_returns_path() {
  RUN_CMD_WORKDIR="$ROOT_DIR" run_spell spells/.imps/test/test-find-repo-root
  assert_success
  [ -n "$OUTPUT" ] || { TEST_FAILURE_REASON="should return a path"; return 1; }
}

run_test_case "test-find-repo-root is executable" test_test_find_repo_root_exists
run_test_case "test-find-repo-root returns path" test_test_find_repo_root_returns_path

finish_tests
