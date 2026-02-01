#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_outputs_event_with_id() {
  run_spell "spells/.imps/cgi/sse-event-id" "message" "msg_123" "Hello world"
  [ "$STATUS" -eq 0 ] || return 1
  printf '%s' "$OUTPUT" | grep -q "id: msg_123" || return 1
  printf '%s' "$OUTPUT" | grep -q "event: message" || return 1
  printf '%s' "$OUTPUT" | grep -q "data: Hello world" || return 1
}

test_handles_empty_id() {
  run_spell "spells/.imps/cgi/sse-event-id" "message" "" "Test data"
  [ "$STATUS" -eq 0 ] || return 1
  printf '%s' "$OUTPUT" | grep -q "event: message" || return 1
  printf '%s' "$OUTPUT" | grep -q "data: Test data" || return 1
  # Should not have id field when empty
  ! printf '%s' "$OUTPUT" | grep -q "^id: $" || return 1
}

run_test_case "outputs event with ID field" test_outputs_event_with_id
run_test_case "handles empty ID gracefully" test_handles_empty_id
finish_tests
