#!/bin/sh
# Tests for the 'there' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_there_exists() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/there_test.XXXXXX")
  run_spell spells/.imps/cond/there "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_there_missing() {
  run_spell spells/.imps/cond/there "$WIZARDRY_TMPDIR/nonexistent_xyz123"
  assert_failure
}

run_test_case "there succeeds for existing path" test_there_exists
run_test_case "there fails for missing path" test_there_missing

finish_tests
