#!/bin/sh
# Tests for the 'sed-inplace' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_sed_inplace_substitutes() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'hello world' > "$tmpfile"
  run_spell spells/.imps/fs/sed-inplace 's/world/universe/' "$tmpfile"
  assert_success
  content=$(cat "$tmpfile")
  [ "$content" = "hello universe" ] || { TEST_FAILURE_REASON="expected 'hello universe' got '$content'"; return 1; }
  rm -f "$tmpfile"
}

test_sed_inplace_global() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'foo foo foo' > "$tmpfile"
  run_spell spells/.imps/fs/sed-inplace 's/foo/bar/g' "$tmpfile"
  assert_success
  content=$(cat "$tmpfile")
  [ "$content" = "bar bar bar" ] || { TEST_FAILURE_REASON="expected 'bar bar bar' got '$content'"; return 1; }
  rm -f "$tmpfile"
}

test_sed_inplace_missing_file_fails() {
  run_spell spells/.imps/fs/sed-inplace 's/a/b/' "/nonexistent/file"
  assert_failure
}

test_sed_inplace_no_pattern_fails() {
  run_spell spells/.imps/fs/sed-inplace
  assert_failure
}

test_sed_inplace_no_file_fails() {
  run_spell spells/.imps/fs/sed-inplace 's/a/b/'
  assert_failure
}

test_sed_inplace_directory_fails() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  run_spell spells/.imps/fs/sed-inplace 's/a/b/' "$tmpdir"
  rmdir "$tmpdir"
  assert_failure
}

run_test_case "sed-inplace substitutes text" test_sed_inplace_substitutes
run_test_case "sed-inplace global flag" test_sed_inplace_global
run_test_case "sed-inplace missing file fails" test_sed_inplace_missing_file_fails
run_test_case "sed-inplace no pattern fails" test_sed_inplace_no_pattern_fails
run_test_case "sed-inplace no file fails" test_sed_inplace_no_file_fails
run_test_case "sed-inplace directory fails" test_sed_inplace_directory_fails

finish_tests
