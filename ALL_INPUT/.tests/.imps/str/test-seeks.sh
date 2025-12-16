#!/bin/sh
# Tests for the 'seeks' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_seeks_finds_pattern() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/seeks_test.XXXXXX")
  printf 'hello world\n' > "$tmpfile"
  _run_spell spells/.imps/str/seeks "wor" "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
}

test_seeks_rejects_missing() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/seeks_test.XXXXXX")
  printf 'hello world\n' > "$tmpfile"
  _run_spell spells/.imps/str/seeks "xyz" "$tmpfile"
  rm -f "$tmpfile"
  _assert_failure
}

_run_test_case "seeks finds pattern" test_seeks_finds_pattern
_run_test_case "seeks rejects missing pattern" test_seeks_rejects_missing

_finish_tests
