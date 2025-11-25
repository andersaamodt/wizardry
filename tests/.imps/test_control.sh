#!/bin/sh
# Tests for control flow imps: ok, quiet, fail, die, full, make

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

test_quiet_succeeds_silently() {
  run_spell spells/.imps/quiet ls /
  assert_success
  if [ -n "$OUTPUT" ]; then
    TEST_FAILURE_REASON="quiet should suppress output"
    return 1
  fi
}

test_fail_exits_with_error() {
  run_spell spells/.imps/fail "test error message"
  assert_failure
  assert_error_contains "test error message"
}

test_die_exits_with_error() {
  run_spell spells/.imps/die "test die message"
  assert_failure
  assert_error_contains "test die message"
}

test_die_with_code() {
  run_spell spells/.imps/die 42 "exit code test"
  assert_status 42
  assert_error_contains "exit code test"
}

test_full_file_with_content() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'content' > "$tmpfile"
  run_spell spells/.imps/full file "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_full_file_empty() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  run_spell spells/.imps/full file "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

test_full_dir_with_entries() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  touch "$tmpdir/file"
  run_spell spells/.imps/full dir "$tmpdir"
  rm -rf "$tmpdir"
  assert_success
}

test_full_dir_empty() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  run_spell spells/.imps/full dir "$tmpdir"
  rmdir "$tmpdir"
  assert_failure
}

test_make_dir() {
  # Test make by running it directly (sandbox creates dirs in WIZARDRY_TMPDIR)
  tmpdir="$WIZARDRY_TMPDIR/make_test_$$"
  "$ROOT_DIR/spells/.imps/make" dir "$tmpdir"
  status=$?
  if [ "$status" -ne 0 ]; then
    TEST_FAILURE_REASON="make dir exited with status $status"
    return 1
  fi
  if [ ! -d "$tmpdir" ]; then
    TEST_FAILURE_REASON="make dir should create directory"
    return 1
  fi
  rmdir "$tmpdir"
}

run_test_case "ok succeeds silently" test_ok_succeeds_silently
run_test_case "ok fails silently" test_ok_fails_silently
run_test_case "quiet succeeds silently" test_quiet_succeeds_silently
run_test_case "fail exits with error" test_fail_exits_with_error
run_test_case "die exits with error" test_die_exits_with_error
run_test_case "die with custom exit code" test_die_with_code
run_test_case "full file with content" test_full_file_with_content
run_test_case "full file empty" test_full_file_empty
run_test_case "full dir with entries" test_full_dir_with_entries
run_test_case "full dir empty" test_full_dir_empty
run_test_case "make dir creates directory" test_make_dir

finish_tests
