#!/bin/sh
# Tests for the 'full' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_full_file_with_content() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/full_test.XXXXXX")
  printf 'content' > "$tmpfile"
  run_spell spells/.imps/cond/full file "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_full_empty_file_fails() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/full_test.XXXXXX")
  : > "$tmpfile"
  run_spell spells/.imps/cond/full file "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

run_test_case "full file succeeds with content" test_full_file_with_content
run_test_case "full file fails for empty" test_full_empty_file_fails

finish_tests
