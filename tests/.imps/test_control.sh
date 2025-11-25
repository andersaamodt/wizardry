#!/bin/sh
# Tests for control flow imps: ok, quiet, fail, die, full, make, temp

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

test_quiet_fails_silently() {
  run_spell spells/.imps/quiet ls /nonexistent_xyz123
  assert_failure
  if [ -n "$ERROR" ]; then
    TEST_FAILURE_REASON="quiet should suppress stderr"
    return 1
  fi
}

test_fail_exits_with_error() {
  run_spell spells/.imps/fail "test error message"
  assert_failure
  assert_error_contains "test error message"
}

test_fail_returns_status_1() {
  run_spell spells/.imps/fail "message"
  assert_status 1
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

test_die_default_code() {
  run_spell spells/.imps/die "just message"
  assert_status 1
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

test_make_dir_idempotent() {
  tmpdir="$WIZARDRY_TMPDIR/make_idem_$$"
  mkdir -p "$tmpdir"
  "$ROOT_DIR/spells/.imps/make" dir "$tmpdir"
  status=$?
  rmdir "$tmpdir"
  if [ "$status" -ne 0 ]; then
    TEST_FAILURE_REASON="make dir should succeed for existing dir"
    return 1
  fi
}

test_temp_creates_file() {
  run_spell spells/.imps/temp testprefix
  assert_success
  # Should output a path
  case "$OUTPUT" in
    *testprefix*) 
      # Clean up created file
      rm -f "$OUTPUT" 2>/dev/null
      return 0 ;;
    *) TEST_FAILURE_REASON="expected path with prefix, got: $OUTPUT"; return 1 ;;
  esac
}

test_temp_default_prefix() {
  run_spell spells/.imps/temp
  assert_success
  case "$OUTPUT" in
    *wizardry*)
      rm -f "$OUTPUT" 2>/dev/null
      return 0 ;;
    *) TEST_FAILURE_REASON="expected default wizardry prefix, got: $OUTPUT"; return 1 ;;
  esac
}

run_test_case "ok succeeds silently" test_ok_succeeds_silently
run_test_case "ok fails silently" test_ok_fails_silently
run_test_case "quiet succeeds silently" test_quiet_succeeds_silently
run_test_case "quiet fails silently" test_quiet_fails_silently
run_test_case "fail exits with error" test_fail_exits_with_error
run_test_case "fail returns status 1" test_fail_returns_status_1
run_test_case "die exits with error" test_die_exits_with_error
run_test_case "die with custom exit code" test_die_with_code
run_test_case "die default code is 1" test_die_default_code
run_test_case "full file with content" test_full_file_with_content
run_test_case "full file empty" test_full_file_empty
run_test_case "full dir with entries" test_full_dir_with_entries
run_test_case "full dir empty" test_full_dir_empty
run_test_case "make dir creates directory" test_make_dir
run_test_case "make dir is idempotent" test_make_dir_idempotent
run_test_case "temp creates file" test_temp_creates_file
run_test_case "temp uses default prefix" test_temp_default_prefix

finish_tests
