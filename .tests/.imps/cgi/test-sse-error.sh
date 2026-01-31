#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_outputs_error_event() {
  run_spell "spells/.imps/cgi/sse-error" "404" "Room not found"
  [ "$STATUS" -eq 0 ] || return 1
  printf '%s' "$OUTPUT" | grep -q "event: error" || return 1
  printf '%s' "$OUTPUT" | grep -q '"code":404' || return 1
  printf '%s' "$OUTPUT" | grep -q '"message":"Room not found"' || return 1
}

test_default_error() {
  run_spell "spells/.imps/cgi/sse-error"
  [ "$STATUS" -eq 0 ] || return 1
  printf '%s' "$OUTPUT" | grep -q "event: error" || return 1
  printf '%s' "$OUTPUT" | grep -q '"code":500' || return 1
  printf '%s' "$OUTPUT" | grep -q "Internal Server Error" || return 1
}

run_test_case "outputs structured error event" test_outputs_error_event
run_test_case "uses default 500 error" test_default_error
finish_tests
