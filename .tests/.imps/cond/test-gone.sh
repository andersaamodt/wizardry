#!/bin/sh
# Tests for the 'gone' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_gone_missing() {
  run_spell spells/.imps/cond/gone "$WIZARDRY_TMPDIR/nonexistent_xyz123"
  assert_success
}

test_gone_exists() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/gone_test.XXXXXX")
  run_spell spells/.imps/cond/gone "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

run_test_case "gone succeeds for missing path" test_gone_missing
run_test_case "gone fails for existing path" test_gone_exists

finish_tests
