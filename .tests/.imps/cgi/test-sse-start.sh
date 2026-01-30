#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_sse_start_exists() {
  [ -x "spells/.imps/cgi/sse-start" ]
}

test_sse_start_outputs_headers() {
  output=$(sse-start 2>&1)
  result=$?
  [ "$result" -eq 0 ] && \
  printf '%s' "$output" | grep -q "Status: 200 OK" && \
  printf '%s' "$output" | grep -q "Content-Type: text/event-stream" && \
  printf '%s' "$output" | grep -q "Cache-Control: no-cache" && \
  printf '%s' "$output" | grep -q "Connection: keep-alive"
}

test_sse_start_ends_with_blank_line() {
  # Check that sse-start output contains the double CRLF sequence
  sse-start 2>&1 | od -An -tx1 | grep -q "0d 0a 0d 0a"
}

run_test_case "sse-start is executable" test_sse_start_exists
run_test_case "sse-start outputs correct SSE headers" test_sse_start_outputs_headers
run_test_case "sse-start ends headers with blank line" test_sse_start_ends_with_blank_line

finish_tests
