#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_outputs_cors_headers() {
  run_spell "spells/.imps/cgi/http-cors" "*"
  [ "$STATUS" -eq 0 ] || return 1
  printf '%s' "$OUTPUT" | grep -q "Access-Control-Allow-Origin: \*" || return 1
  printf '%s' "$OUTPUT" | grep -q "Access-Control-Allow-Methods" || return 1
}

test_cors_with_specific_origin() {
  run_spell "spells/.imps/cgi/http-cors" "https://example.com"
  [ "$STATUS" -eq 0 ] || return 1
  printf '%s' "$OUTPUT" | grep -q "Access-Control-Allow-Origin: https://example.com" || return 1
  printf '%s' "$OUTPUT" | grep -q "Access-Control-Allow-Credentials: true" || return 1
}

test_cors_headers_for_sse() {
  run_spell "spells/.imps/cgi/http-cors" "*"
  [ "$STATUS" -eq 0 ] || return 1
  # Should allow Last-Event-ID header for SSE resumption
  printf '%s' "$OUTPUT" | grep -q "Last-Event-ID" || return 1
}

run_test_case "outputs CORS headers with wildcard origin" test_outputs_cors_headers
run_test_case "outputs CORS headers with specific origin" test_cors_with_specific_origin
run_test_case "includes Last-Event-ID for SSE resumption" test_cors_headers_for_sse
finish_tests
