#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_outputs_retry_field() {
  run_spell "spells/.imps/cgi/sse-retry" "5000"
  [ "$STATUS" -eq 0 ] || return 1
  printf '%s' "$OUTPUT" | grep -q "retry: 5000" || return 1
}

test_default_retry_value() {
  run_spell "spells/.imps/cgi/sse-retry"
  [ "$STATUS" -eq 0 ] || return 1
  printf '%s' "$OUTPUT" | grep -q "retry: 3000" || return 1
}

run_test_case "outputs retry field with specified value" test_outputs_retry_field
run_test_case "uses default 3000ms when no value provided" test_default_retry_value
finish_tests
