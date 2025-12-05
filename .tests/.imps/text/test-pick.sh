#!/bin/sh
# Tests for the 'pick' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_pick_selects_line() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/pick_test.XXXXXX")
  printf 'one\ntwo\nthree\n' > "$tmpfile"
  run_spell spells/.imps/text/pick 2 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "two"
}

test_pick_selects_first_line() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/pick_test.XXXXXX")
  printf 'first\nsecond\n' > "$tmpfile"
  run_spell spells/.imps/text/pick 1 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "first"
}

run_test_case "pick selects line by number" test_pick_selects_line
run_test_case "pick selects first line" test_pick_selects_first_line

finish_tests
