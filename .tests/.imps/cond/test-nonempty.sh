#!/bin/sh
# Tests for the 'nonempty' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_nonempty_succeeds_for_nonempty() {
  run_spell spells/.imps/cond/nonempty "something"
  assert_success
}

test_nonempty_fails_for_empty() {
  run_spell spells/.imps/cond/nonempty ""
  assert_failure
}

run_test_case "nonempty succeeds for non-empty string" test_nonempty_succeeds_for_nonempty
run_test_case "nonempty fails for empty string" test_nonempty_fails_for_empty

finish_tests
