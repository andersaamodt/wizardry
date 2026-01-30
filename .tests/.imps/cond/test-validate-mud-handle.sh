#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_validates_alphanumeric() {
  run_spell "spells/.imps/cond/validate-mud-handle" "player123"
  assert_success
}

test_validates_with_dash() {
  run_spell "spells/.imps/cond/validate-mud-handle" "dark-knight"
  assert_success
}

test_validates_with_underscore() {
  run_spell "spells/.imps/cond/validate-mud-handle" "super_user"
  assert_success
}

test_rejects_empty() {
  run_spell "spells/.imps/cond/validate-mud-handle" ""
  assert_failure
}

test_rejects_spaces() {
  run_spell "spells/.imps/cond/validate-mud-handle" "my username"
  assert_failure
}

test_rejects_special_chars() {
  run_spell "spells/.imps/cond/validate-mud-handle" "user@123"
  assert_failure
}

test_rejects_at_symbol() {
  run_spell "spells/.imps/cond/validate-mud-handle" "@player"
  assert_failure
}

run_test_case "validates alphanumeric handles" test_validates_alphanumeric
run_test_case "validates handles with dash" test_validates_with_dash
run_test_case "validates handles with underscore" test_validates_with_underscore
run_test_case "rejects empty handle" test_rejects_empty
run_test_case "rejects handles with spaces" test_rejects_spaces
run_test_case "rejects handles with special characters" test_rejects_special_chars
run_test_case "rejects handles with @ symbol" test_rejects_at_symbol
finish_tests
