#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_outputs_error_response() {
  run_spell "spells/.imps/cgi/http-error" "404" "Not Found"
  [ "$STATUS" -eq 0 ] || return 1
  printf '%s' "$OUTPUT" | grep -q "Status: 404 Not Found" || return 1
  printf '%s' "$OUTPUT" | grep -q "Error 404" || return 1
  printf '%s' "$OUTPUT" | grep -q "Not Found" || return 1
}

test_default_500_error() {
  run_spell "spells/.imps/cgi/http-error"
  [ "$STATUS" -eq 0 ] || return 1
  printf '%s' "$OUTPUT" | grep -q "Status: 500" || return 1
  printf '%s' "$OUTPUT" | grep -q "Internal Server Error" || return 1
}

run_test_case "outputs error response with correct format" test_outputs_error_response
run_test_case "defaults to 500 error" test_default_500_error
finish_tests
