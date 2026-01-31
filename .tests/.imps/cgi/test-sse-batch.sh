#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_starts_event_batch() {
  run_spell "spells/.imps/cgi/sse-batch" "message"
  [ "$STATUS" -eq 0 ] || return 1
  printf '%s' "$OUTPUT" | grep -q "event: message" || return 1
}

test_batch_with_custom_type() {
  run_spell "spells/.imps/cgi/sse-batch" "update"
  [ "$STATUS" -eq 0 ] || return 1
  printf '%s' "$OUTPUT" | grep -q "event: update" || return 1
}

run_test_case "starts event batch with type" test_starts_event_batch
run_test_case "supports custom event types" test_batch_with_custom_type
finish_tests
