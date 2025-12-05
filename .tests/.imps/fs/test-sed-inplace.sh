#!/bin/sh
# Tests for the 'sed-inplace' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_sed_inplace_substitutes() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'hello world' > "$tmpfile"
  _run_spell spells/.imps/fs/sed-inplace 's/world/universe/' "$tmpfile"
  _assert_success
  content=$(cat "$tmpfile")
  [ "$content" = "hello universe" ] || { TEST_FAILURE_REASON="expected 'hello universe' got '$content'"; return 1; }
  rm -f "$tmpfile"
}

test_sed_inplace_global() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'foo foo foo' > "$tmpfile"
  _run_spell spells/.imps/fs/sed-inplace 's/foo/bar/g' "$tmpfile"
  _assert_success
  content=$(cat "$tmpfile")
  [ "$content" = "bar bar bar" ] || { TEST_FAILURE_REASON="expected 'bar bar bar' got '$content'"; return 1; }
  rm -f "$tmpfile"
}

test_sed_inplace_missing_file_fails() {
  _run_spell spells/.imps/fs/sed-inplace 's/a/b/' "/nonexistent/file"
  _assert_failure
}

test_sed_inplace_no_pattern_fails() {
  _run_spell spells/.imps/fs/sed-inplace
  _assert_failure
}

test_sed_inplace_no_file_fails() {
  _run_spell spells/.imps/fs/sed-inplace 's/a/b/'
  _assert_failure
}

test_sed_inplace_directory_fails() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  _run_spell spells/.imps/fs/sed-inplace 's/a/b/' "$tmpdir"
  rmdir "$tmpdir"
  _assert_failure
}

_run_test_case "sed-inplace substitutes text" test_sed_inplace_substitutes
_run_test_case "sed-inplace global flag" test_sed_inplace_global
_run_test_case "sed-inplace missing file fails" test_sed_inplace_missing_file_fails
_run_test_case "sed-inplace no pattern fails" test_sed_inplace_no_pattern_fails
_run_test_case "sed-inplace no file fails" test_sed_inplace_no_file_fails
_run_test_case "sed-inplace directory fails" test_sed_inplace_directory_fails

_finish_tests
