#!/bin/sh
# Tests for control flow imps: ok, fail, nonempty

. "${0%/*}/../test_common.sh"

test_ok_succeeds_silently() {
  run_spell spells/.imps/ok ls /
  assert_success
  # Output should be empty (silent)
  if [ -n "$OUTPUT" ]; then
    TEST_FAILURE_REASON="ok should suppress output"
    return 1
  fi
}

test_ok_fails_silently() {
  run_spell spells/.imps/ok ls /nonexistent_path_xyz123
  assert_failure
  # stderr should also be suppressed
  if [ -n "$ERROR" ]; then
    TEST_FAILURE_REASON="ok should suppress stderr"
    return 1
  fi
}

test_fail_exits_with_error() {
  run_spell spells/.imps/fail "test error message"
  assert_failure
  assert_error_contains "test error message"
}

test_nonempty_file_with_content() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'content' > "$tmpfile"
  run_spell spells/.imps/nonempty file "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_nonempty_file_empty() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  run_spell spells/.imps/nonempty file "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

test_nonempty_dir_with_entries() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  touch "$tmpdir/file"
  run_spell spells/.imps/nonempty dir "$tmpdir"
  rm -rf "$tmpdir"
  assert_success
}

test_nonempty_dir_empty() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  run_spell spells/.imps/nonempty dir "$tmpdir"
  rmdir "$tmpdir"
  assert_failure
}

run_test_case "ok succeeds silently" test_ok_succeeds_silently
run_test_case "ok fails silently" test_ok_fails_silently
run_test_case "fail exits with error" test_fail_exits_with_error
run_test_case "nonempty file with content" test_nonempty_file_with_content
run_test_case "nonempty file empty" test_nonempty_file_empty
run_test_case "nonempty dir with entries" test_nonempty_dir_with_entries
run_test_case "nonempty dir empty" test_nonempty_dir_empty

finish_tests
