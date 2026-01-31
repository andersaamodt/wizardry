#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_generates_2kb_padding_by_default() {
  run_spell "spells/.imps/cgi/sse-padding"
  [ "$STATUS" -eq 0 ] || return 1
  # Should be roughly 2KB (2000 chars + prefix + newline)
  length=$(printf '%s' "$OUTPUT" | wc -c | tr -d ' ')
  [ "$length" -ge 2000 ] || return 1
  [ "$length" -le 2100 ] || return 1
}

test_generates_4kb_padding_when_specified() {
  run_spell "spells/.imps/cgi/sse-padding" 4
  [ "$STATUS" -eq 0 ] || return 1
  # Should be roughly 4KB (4000 chars + prefix + newline)
  length=$(printf '%s' "$OUTPUT" | wc -c | tr -d ' ')
  [ "$length" -ge 4000 ] || return 1
  [ "$length" -le 4100 ] || return 1
}

test_starts_with_sse_comment_prefix() {
  run_spell "spells/.imps/cgi/sse-padding"
  [ "$STATUS" -eq 0 ] || return 1
  printf '%s' "$OUTPUT" | grep -q ": padding=" || return 1
}

test_ends_with_newline() {
  run_spell "spells/.imps/cgi/sse-padding"
  [ "$STATUS" -eq 0 ] || return 1
  # Last character should be newline
  printf '%s' "$OUTPUT" | tail -c 1 | od -An -tx1 | grep -q "0a"
}

run_test_case "generates 2KB padding by default" test_generates_2kb_padding_by_default
run_test_case "generates 4KB padding when specified" test_generates_4kb_padding_when_specified
run_test_case "starts with SSE comment prefix" test_starts_with_sse_comment_prefix
run_test_case "ends with newline" test_ends_with_newline
finish_tests
