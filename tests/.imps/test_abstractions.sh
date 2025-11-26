#!/bin/sh
# Tests for imps: pick, now, empty, nonempty, given (deprecated), must

. "${0%/*}/../test_common.sh"

# pick tests
test_pick_line() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/pick_test.XXXXXX")
  printf 'first\nsecond\nthird\n' > "$tmpfile"
  run_spell spells/.imps/pick 2 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "second"
}

test_pick_from_stdin() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/pick_test.XXXXXX")
  printf 'first\nsecond\nthird\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | $ROOT_DIR/spells/.imps/pick 3"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "third"
}

# now tests
test_now_outputs_timestamp() {
  run_spell spells/.imps/now
  assert_success
  # Output should be numeric (epoch seconds) or a PID fallback
  case "$OUTPUT" in
    *[0-9]*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="expected numeric output"
      return 1
      ;;
  esac
}

test_now_with_format() {
  run_spell spells/.imps/now "%Y"
  assert_success
  # Should output a 4-digit year
  case "$OUTPUT" in
    20[0-9][0-9])
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="expected 4-digit year, got $OUTPUT"
      return 1
      ;;
  esac
}

# empty tests
test_empty_true_for_empty() {
  run_spell spells/.imps/empty ""
  assert_success
}

test_empty_false_for_value() {
  run_spell spells/.imps/empty "some value"
  assert_failure
}

# nonempty tests (preferred over deprecated 'given')
test_nonempty_true_for_value() {
  run_spell spells/.imps/nonempty "some value"
  assert_success
}

test_nonempty_false_for_empty() {
  run_spell spells/.imps/nonempty ""
  assert_failure
}

test_nonempty_with_whitespace() {
  run_spell spells/.imps/nonempty "   "
  assert_success
}

test_nonempty_with_zero() {
  run_spell spells/.imps/nonempty "0"
  assert_success
}

# given tests (deprecated, kept for backward compatibility)
test_given_true_for_value() {
  run_spell spells/.imps/given "some value"
  assert_success
}

test_given_false_for_empty() {
  run_spell spells/.imps/given ""
  assert_failure
}

# must tests
test_must_has_succeeds() {
  run_spell spells/.imps/must has sh
  assert_success
}

test_must_has_fails_with_message() {
  run_spell spells/.imps/must has nonexistent_cmd_xyz123
  assert_failure
  assert_error_contains "nonexistent_cmd_xyz123"
}

test_must_has_custom_message() {
  run_spell spells/.imps/must has nonexistent_cmd_xyz123 "custom error msg"
  assert_failure
  assert_error_contains "custom error msg"
}

test_must_there_succeeds() {
  run_spell spells/.imps/must there /tmp
  assert_success
}

test_must_there_fails() {
  run_spell spells/.imps/must there /nonexistent_path_xyz123
  assert_failure
  assert_error_contains "/nonexistent_path_xyz123"
}

test_must_file_succeeds() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/must_test.XXXXXX")
  run_spell spells/.imps/must file "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_must_file_fails() {
  run_spell spells/.imps/must file "/nonexistent_file_xyz123"
  assert_failure
  assert_error_contains "/nonexistent_file_xyz123"
}

test_must_set_succeeds() {
  run_spell spells/.imps/must set "nonempty"
  assert_success
}

test_must_set_fails() {
  run_spell spells/.imps/must set ""
  assert_failure
  assert_error_contains "value not provided"
}

# Additional must tests for better coverage
test_must_dir_succeeds() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/must_dir.XXXXXX")
  run_spell spells/.imps/must dir "$tmpdir"
  rmdir "$tmpdir"
  assert_success
}

test_must_dir_fails() {
  run_spell spells/.imps/must dir "/nonexistent_dir_xyz123"
  assert_failure
  assert_error_contains "/nonexistent_dir_xyz123"
}

test_must_exec_succeeds() {
  run_spell spells/.imps/must exec /bin/sh
  assert_success
}

test_must_exec_fails() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/must_noexec.XXXXXX")
  chmod -x "$tmpfile"
  run_spell spells/.imps/must exec "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

test_must_readable_succeeds() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/must_read.XXXXXX")
  run_spell spells/.imps/must readable "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_must_unknown_type_fails() {
  run_spell spells/.imps/must unknowntype "/tmp"
  assert_failure
  assert_error_contains "unknown test type"
}

test_must_custom_message() {
  run_spell spells/.imps/must dir "/nonexistent_xyz" "custom dir error"
  assert_failure
  assert_error_contains "custom dir error"
}

run_test_case "pick extracts specific line" test_pick_line
run_test_case "pick works with stdin" test_pick_from_stdin
run_test_case "now outputs timestamp" test_now_outputs_timestamp
run_test_case "now formats with pattern" test_now_with_format
run_test_case "empty is true for empty string" test_empty_true_for_empty
run_test_case "empty is false for value" test_empty_false_for_value
run_test_case "nonempty is true for value" test_nonempty_true_for_value
run_test_case "nonempty is false for empty" test_nonempty_false_for_empty
run_test_case "nonempty is true for whitespace only" test_nonempty_with_whitespace
run_test_case "nonempty is true for zero" test_nonempty_with_zero
run_test_case "given (deprecated) is true for value" test_given_true_for_value
run_test_case "given (deprecated) is false for empty" test_given_false_for_empty
run_test_case "must has succeeds for existing command" test_must_has_succeeds
run_test_case "must has fails with default message" test_must_has_fails_with_message
run_test_case "must has fails with custom message" test_must_has_custom_message
run_test_case "must there succeeds for existing path" test_must_there_succeeds
run_test_case "must there fails for missing path" test_must_there_fails
run_test_case "must file succeeds for file" test_must_file_succeeds
run_test_case "must file fails for missing" test_must_file_fails
run_test_case "must set succeeds for non-empty" test_must_set_succeeds
run_test_case "must set fails for empty" test_must_set_fails
run_test_case "must dir succeeds for directory" test_must_dir_succeeds
run_test_case "must dir fails for missing" test_must_dir_fails
run_test_case "must exec succeeds for executable" test_must_exec_succeeds
run_test_case "must exec fails for non-executable" test_must_exec_fails
run_test_case "must readable succeeds for readable file" test_must_readable_succeeds
run_test_case "must unknown type fails" test_must_unknown_type_fails
run_test_case "must dir with custom message" test_must_custom_message

finish_tests
