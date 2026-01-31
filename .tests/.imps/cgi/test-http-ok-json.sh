#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_outputs_correct_headers() {
  run_spell "spells/.imps/cgi/http-ok-json"
  [ "$STATUS" -eq 0 ] || return 1
  printf '%s' "$OUTPUT" | grep -q "Status: 200 OK" || return 1
  printf '%s' "$OUTPUT" | grep -q "Content-Type: application/json" || return 1
}

run_test_case "outputs correct HTTP headers for JSON" test_outputs_correct_headers
finish_tests
