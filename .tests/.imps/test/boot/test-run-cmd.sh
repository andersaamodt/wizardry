#!/bin/sh
# Test run-cmd imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_captures_stdout() {
  run_cmd printf "hello"
  [ "$OUTPUT" = "hello" ]
}

test_captures_exit_status() {
  run_cmd sh -c "exit 42"
  [ "$STATUS" -eq 42 ]
}

test_captures_stderr() {
  run_cmd sh -c 'printf "error" >&2'
  [ "$ERROR" = "error" ]
}

run_test_case "run-cmd captures stdout" test_captures_stdout
run_test_case "run-cmd captures exit status" test_captures_exit_status
run_test_case "run-cmd captures stderr" test_captures_stderr

finish_tests
