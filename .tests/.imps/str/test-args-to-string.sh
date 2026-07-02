#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_joins_arguments_with_single_spaces() {
  run_cmd "$ROOT_DIR/spells/.imps/str/args-to-string" a simple pong game
  assert_success || return 1
  assert_equals "$OUTPUT" "a simple pong game" || return 1
}

test_preserves_spaces_inside_arguments() {
  run_cmd "$ROOT_DIR/spells/.imps/str/args-to-string" "simple pong" "Godot 4"
  assert_success || return 1
  assert_equals "$OUTPUT" "simple pong Godot 4" || return 1
}

test_no_arguments_outputs_blank_line() {
  run_cmd "$ROOT_DIR/spells/.imps/str/args-to-string"
  assert_success || return 1
  assert_equals "$OUTPUT" "" || return 1
}

run_test_case "args-to-string joins arguments" test_joins_arguments_with_single_spaces
run_test_case "args-to-string preserves argument internals" test_preserves_spaces_inside_arguments
run_test_case "args-to-string handles no arguments" test_no_arguments_outputs_blank_line

finish_tests
