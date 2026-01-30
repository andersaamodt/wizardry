#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_sse_event_exists() {
  [ -x "spells/.imps/cgi/sse-event" ]
}

test_sse_event_with_type_and_data() {
  output=$(sse-event message "Hello World" 2>&1)
  result=$?
  [ "$result" -eq 0 ] && \
  printf '%s' "$output" | grep -q "event: message" && \
  printf '%s' "$output" | grep -q "data: Hello World"
}

test_sse_event_with_multiline_data() {
  output=$(sse-event test "Line 1
Line 2
Line 3" 2>&1)
  result=$?
  [ "$result" -eq 0 ] && \
  printf '%s' "$output" | grep -q "event: test" && \
  printf '%s' "$output" | grep -q "data: Line 1" && \
  printf '%s' "$output" | grep -q "data: Line 2" && \
  printf '%s' "$output" | grep -q "data: Line 3"
}

test_sse_event_defaults_to_message_type() {
  output=$(sse-event 2>&1)
  result=$?
  [ "$result" -eq 0 ] && \
  printf '%s' "$output" | grep -q "event: message"
}

test_sse_event_ends_with_blank_line() {
  # Should end with double newline (0a 0a in hex)
  sse-event message "test" 2>&1 | od -An -tx1 | grep -q "0a 0a"
}

test_sse_event_handles_empty_data() {
  output=$(sse-event status "" 2>&1)
  result=$?
  [ "$result" -eq 0 ] && \
  printf '%s' "$output" | grep -q "event: status"
}

run_test_case "sse-event is executable" test_sse_event_exists
run_test_case "sse-event outputs event with type and data" test_sse_event_with_type_and_data
run_test_case "sse-event handles multiline data" test_sse_event_with_multiline_data
run_test_case "sse-event defaults to message type" test_sse_event_defaults_to_message_type
run_test_case "sse-event ends with blank line" test_sse_event_ends_with_blank_line
run_test_case "sse-event handles empty data" test_sse_event_handles_empty_data

finish_tests
