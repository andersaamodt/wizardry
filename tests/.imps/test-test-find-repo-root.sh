#!/bin/sh
# Tests for the 'test-find-repo-root' imp

. "${0%/*}/../test-common.sh"

test_test_find_repo_root_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test-find-repo-root" ]
}

run_test_case "test-find-repo-root is executable" test_test_find_repo_root_exists

finish_tests
