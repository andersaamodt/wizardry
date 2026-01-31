#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_outputs_correct_headers() {
  run_spell "spells/.imps/cgi/http-ok-html"
  [ "$STATUS" -eq 0 ] || return 1
  printf '%s' "$OUTPUT" | grep -q "Status: 200 OK" || return 1
  printf '%s' "$OUTPUT" | grep -q "Content-Type: text/html" || return 1
}

test_ends_with_blank_line() {
  run_spell "spells/.imps/cgi/http-ok-html"
  [ "$STATUS" -eq 0 ] || return 1
  # Should contain the CRLF blank line that ends headers
  printf '%s' "$OUTPUT" | tail -c 4 | od -An -tx1 | grep -q "0d 0a 0d 0a"
}

run_test_case "outputs correct HTTP headers for HTML" test_outputs_correct_headers
run_test_case "ends with blank line to terminate headers" test_ends_with_blank_line
finish_tests
