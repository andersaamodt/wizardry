#!/bin/sh
# Tests for the 'newer' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_newer_file() {
  old=$(mktemp "$WIZARDRY_TMPDIR/older.XXXXXX")
  sleep 1
  new=$(mktemp "$WIZARDRY_TMPDIR/newer.XXXXXX")
  run_spell spells/.imps/cond/newer "$new" "$old"
  rm -f "$old" "$new"
  assert_success
}

test_newer_fails_for_older_file() {
  old=$(mktemp "$WIZARDRY_TMPDIR/older.XXXXXX")
  sleep 1
  new=$(mktemp "$WIZARDRY_TMPDIR/newer.XXXXXX")
  run_spell spells/.imps/cond/newer "$old" "$new"
  rm -f "$old" "$new"
  assert_failure
}

run_test_case "newer detects newer file" test_newer_file
run_test_case "newer fails for older file" test_newer_fails_for_older_file

finish_tests
