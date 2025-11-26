#!/bin/sh
# Tests for the 'find-repo-root' imp

. "${0%/*}/../test_common.sh"

test_find_repo_root_exists() {
  [ -x "$ROOT_DIR/spells/.imps/find-repo-root" ]
}

run_test_case "find-repo-root is executable" test_find_repo_root_exists

finish_tests
