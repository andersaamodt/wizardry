#!/bin/sh
# Tests for the 'is-path' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_is_path_absolute() {
  run_spell spells/.imps/cond/is-path "/tmp/test"
  assert_success
}

test_is_path_relative() {
  run_spell spells/.imps/cond/is-path "relative/path"
  assert_success
}

test_is_path_filename() {
  run_spell spells/.imps/cond/is-path "file.txt"
  assert_success
}

test_is_path_dot() {
  run_spell spells/.imps/cond/is-path "."
  assert_success
}

test_is_path_dotdot() {
  run_spell spells/.imps/cond/is-path ".."
  assert_success
}

test_is_path_home() {
  run_spell spells/.imps/cond/is-path "~"
  assert_success
}

test_is_path_fails_for_empty() {
  run_spell spells/.imps/cond/is-path ""
  assert_failure
}

run_test_case "is-path succeeds for absolute path" test_is_path_absolute
run_test_case "is-path succeeds for relative path" test_is_path_relative
run_test_case "is-path succeeds for filename" test_is_path_filename
run_test_case "is-path succeeds for dot" test_is_path_dot
run_test_case "is-path succeeds for dotdot" test_is_path_dotdot
run_test_case "is-path succeeds for tilde" test_is_path_home
run_test_case "is-path fails for empty" test_is_path_fails_for_empty

finish_tests
