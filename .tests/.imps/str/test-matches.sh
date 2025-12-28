#!/bin/sh
# Tests for the 'matches' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_matches_pattern() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/matches_test.XXXXXX")
  printf 'hello123\n' > "$tmpfile"
  run_spell spells/.imps/str/matches "[a-z]*[0-9]*" "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_matches_rejects_nonmatch() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/matches_test.XXXXXX")
  printf 'hello\n' > "$tmpfile"
  run_spell spells/.imps/str/matches "^[0-9]+$" "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

run_test_case "matches finds pattern" test_matches_pattern
run_test_case "matches rejects non-match" test_matches_rejects_nonmatch

finish_tests
