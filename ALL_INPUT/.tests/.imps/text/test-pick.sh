#!/bin/sh
# Tests for the 'pick' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pick_selects_line() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/pick_test.XXXXXX")
  printf 'one\ntwo\nthree\n' > "$tmpfile"
  _run_spell spells/.imps/text/pick 2 "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
  _assert_output_contains "two"
}

test_pick_selects_first_line() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/pick_test.XXXXXX")
  printf 'first\nsecond\n' > "$tmpfile"
  _run_spell spells/.imps/text/pick 1 "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
  _assert_output_contains "first"
}

_run_test_case "pick selects line by number" test_pick_selects_line
_run_test_case "pick selects first line" test_pick_selects_first_line

_finish_tests
