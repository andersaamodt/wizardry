#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_outputs_environment_table() {
  export REQUEST_METHOD="GET"
  export QUERY_STRING="test=1"
  run_spell "spells/.imps/cgi/cgi-env"
  [ "$STATUS" -eq 0 ] || return 1
  printf '%s' "$OUTPUT" | grep -q "CGI Environment" || return 1
  printf '%s' "$OUTPUT" | grep -q "REQUEST_METHOD" || return 1
  printf '%s' "$OUTPUT" | grep -q "GET" || return 1
}

test_escapes_html_in_values() {
  export QUERY_STRING="<script>alert('xss')</script>"
  run_spell "spells/.imps/cgi/cgi-env"
  [ "$STATUS" -eq 0 ] || return 1
  # Should escape HTML entities
  printf '%s' "$OUTPUT" | grep -q "&lt;script&gt;" || return 1
  ! printf '%s' "$OUTPUT" | grep -q "<script>" || return 1
}

run_test_case "outputs CGI environment as HTML table" test_outputs_environment_table
run_test_case "escapes HTML in variable values" test_escapes_html_in_values
finish_tests
