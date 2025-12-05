#!/bin/sh
# Tests for the 'full' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

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
