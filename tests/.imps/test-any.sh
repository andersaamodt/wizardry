#!/bin/sh
# Tests for the 'any' imp

. "${0%/*}/../test-common.sh"

test_any_finds_first() {
  run_spell spells/.imps/any sh nonexistent_xyz
  assert_success
  assert_output_contains "sh"
}

test_any_finds_second() {
  run_spell spells/.imps/any nonexistent_xyz sh
  assert_success
  assert_output_contains "sh"
}

test_any_fails_when_none_exist() {
  run_spell spells/.imps/any nonexistent_xyz1 nonexistent_xyz2
  assert_failure
}

run_test_case "any finds first available" test_any_finds_first
run_test_case "any finds second if first missing" test_any_finds_second
run_test_case "any fails when none exist" test_any_fails_when_none_exist

finish_tests
