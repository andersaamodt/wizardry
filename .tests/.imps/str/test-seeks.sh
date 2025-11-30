#!/bin/sh
# Tests for the 'seeks' imp

. "${0%/*}/../../test-common.sh"

test_seeks_finds_pattern() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/seeks_test.XXXXXX")
  printf 'hello world\n' > "$tmpfile"
  run_spell spells/.imps/str/seeks "wor" "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_seeks_rejects_missing() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/seeks_test.XXXXXX")
  printf 'hello world\n' > "$tmpfile"
  run_spell spells/.imps/str/seeks "xyz" "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

run_test_case "seeks finds pattern" test_seeks_finds_pattern
run_test_case "seeks rejects missing pattern" test_seeks_rejects_missing

finish_tests
