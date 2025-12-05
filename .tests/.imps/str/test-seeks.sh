#!/bin/sh
# Tests for the 'seeks' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

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
