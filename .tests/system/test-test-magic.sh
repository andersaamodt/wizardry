#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/system/test-magic" ]
}

shows_help() {
  _run_spell spells/system/test-magic --help
  _assert_success
  _assert_output_contains "Usage:"
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/system/test-magic" ]
}

# Regression test for file descriptor bug (issue #XXX)
# When tests inherit stdin from the loop reading the test list file,
# tests that read from stdin can consume lines from the test list.
# This verifies all tests are processed correctly.
all_tests_are_processed() {
  # Run test-magic directly and capture output
  tmpfile=$(mktemp)
  "$ROOT_DIR/spells/system/test-magic" --only "common-tests.sh" >"$tmpfile" 2>&1 || true
  
  # Extract the test heading (e.g., [1/1])
  last_heading=$(grep -E '^\[[0-9]+/[0-9]+\]' "$tmpfile" | tail -1)
  
  # Parse test count and total from heading like "[1/1]"
  # Use awk for reliable cross-platform parsing
  test_count=$(printf '%s\n' "$last_heading" | awk -F'[][]' '{print $2}' | awk -F'/' '{print $1}')
  test_total=$(printf '%s\n' "$last_heading" | awk -F'[][]' '{print $2}' | awk -F'/' '{print $2}')
  
  # Extract summary line
  summary=$(grep "^Summary:" "$tmpfile")
  
  # Parse counts from "Summary: X passed, Y failed, ..."
  # Use awk for reliable cross-platform parsing
  passed=$(printf '%s\n' "$summary" | awk '{for(i=1;i<=NF;i++) if($(i+1)=="passed,") print $i}')
  failed=$(printf '%s\n' "$summary" | awk '{for(i=1;i<=NF;i++) if($(i+1)=="failed,") print $i}')
  
  rm -f "$tmpfile"
  
  # Verify we got values
  [ -n "$test_count" ] && [ -n "$test_total" ] && [ -n "$passed" ] && [ -n "$failed" ] || {
    printf "FAIL: Could not parse output (count=%s total=%s passed=%s failed=%s)\n" \
      "$test_count" "$test_total" "$passed" "$failed" >&2
    return 1
  }
  
  # Verify test count matches total
  [ "$test_count" = "$test_total" ] || {
    printf "FAIL: Test count mismatch: last test is [%s/%s]\n" "$test_count" "$test_total" >&2
    return 1
  }
  
  # Verify total matches summary
  actual_total=$((passed + failed))
  [ "$test_total" = "$actual_total" ] || {
    printf "FAIL: Total mismatch: shows [%s/%s] but summary is %s passed + %s failed = %s\n" \
      "$test_count" "$test_total" "$passed" "$failed" "$actual_total" >&2
    return 1
  }
  
  return 0
}

# Verify the rerun message format (issue requirement #4)
rerun_message_format_correct() {
  # The message should be: "<=10 failing tests; rerunning only those tests with --very-verbose:"
  # NOT: "GitHub Actions detected <=10 failing tests; rerunning ONLY those tests..."
  
  # Check the source code directly since triggering the message requires failures
  grep -q "rerunning only those tests with --very-verbose:" "$ROOT_DIR/spells/system/test-magic" || {
    printf "FAIL: Rerun message not updated correctly\n" >&2
    return 1
  }
  
  # Verify old message is gone
  grep -q "GitHub Actions detected" "$ROOT_DIR/spells/system/test-magic" && {
    printf "FAIL: Old 'GitHub Actions detected' message still present\n" >&2
    return 1
  }
  
  grep -q "rerunning ONLY those" "$ROOT_DIR/spells/system/test-magic" && {
    printf "FAIL: Old 'ONLY' (uppercase) still present\n" >&2
    return 1
  }
  
  return 0
}

_run_test_case "system/test-magic is executable" spell_is_executable
_run_test_case "system/test-magic shows help" shows_help
_run_test_case "system/test-magic has content" spell_has_content
_run_test_case "system/test-magic processes all tests without skipping" all_tests_are_processed
_run_test_case "system/test-magic rerun message format is correct" rerun_message_format_correct

_finish_tests
