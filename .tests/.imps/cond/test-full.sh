#!/bin/sh
# Tests for the 'full' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_full_file_with_content() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/full_test.XXXXXX")
  printf 'content' > "$tmpfile"
  _run_spell spells/.imps/cond/full file "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
}

test_full_empty_file_fails() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/full_test.XXXXXX")
  : > "$tmpfile"
  _run_spell spells/.imps/cond/full file "$tmpfile"
  rm -f "$tmpfile"
  _assert_failure
}

_run_test_case "full file succeeds with content" test_full_file_with_content
_run_test_case "full file fails for empty" test_full_empty_file_fails

_finish_tests
