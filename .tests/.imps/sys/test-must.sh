#!/bin/sh
# Tests for the 'must' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_must_file_exists() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/must_test.XXXXXX")
  run_spell spells/.imps/sys/must file "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_must_file_fails_for_missing() {
  run_spell spells/.imps/sys/must file "$WIZARDRY_TMPDIR/nonexistent_xyz123"
  assert_failure
  assert_error_contains "file not found"
}

run_test_case "must file succeeds for existing file" test_must_file_exists
run_test_case "must file fails for missing" test_must_file_fails_for_missing

finish_tests
