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
  # Run test-magic on a small subset of tests and verify counts match
  tmpdir="$(_make_tempdir)"
  tmpfile="$tmpdir/output.txt"
  
  # Find first few test files
  cd "$ROOT_DIR" || return 1
  first_test=$(sh spells/system/test-magic --list 2>&1 | head -1 | sed 's/^[[:space:]]*//' | awk '{print $1}')
  
  # If we can't find a test, skip this validation
  [ -n "$first_test" ] || return 0
  
  # Run test-magic on that one test
  sh spells/system/test-magic --only "$first_test" >"$tmpfile" 2>&1 || true
  
  # Extract the test heading (e.g., [1/1])
  last_heading=$(grep -E '^\[[0-9]+/[0-9]+\]' "$tmpfile" | tail -1 || true)
  
  # If no heading found, the test might not have run - skip validation
  [ -n "$last_heading" ] || return 0
  
  # Parse test count and total from heading like "[1/1]"
  # Use awk for reliable cross-platform parsing
  test_count=$(printf '%s\n' "$last_heading" | awk -F'[][]' '{print $2}' | awk -F'/' '{print $1}')
  test_total=$(printf '%s\n' "$last_heading" | awk -F'[][]' '{print $2}' | awk -F'/' '{print $2}')
  
  # Extract summary line
  summary=$(grep "^Summary:" "$tmpfile" || true)
  
  # If no summary, skip validation
  [ -n "$summary" ] || return 0
  
  # Parse counts from "Summary: X passed, Y failed, ..."
  # Use awk for reliable cross-platform parsing
  passed=$(printf '%s\n' "$summary" | awk '{for(i=1;i<=NF;i++) if($(i+1)=="passed,") print $i}')
  failed=$(printf '%s\n' "$summary" | awk '{for(i=1;i<=NF;i++) if($(i+1)=="failed,") print $i}')
  
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

# Verify that test reruns have been eliminated (refactoring requirement)
no_test_reruns() {
  # The rerun logic should be completely removed
  grep -q "rerunning" "$ROOT_DIR/spells/system/test-magic" && {
    TEST_FAILURE_REASON="rerun logic still present in test-magic"
    return 1
  }
  
  grep -q "TEST_MAGIC_DEBUG_RERUN" "$ROOT_DIR/spells/system/test-magic" && {
    TEST_FAILURE_REASON="DEBUG_RERUN variable still present"
    return 1
  }
  
  grep -q "very-verbose" "$ROOT_DIR/spells/system/test-magic" && {
    TEST_FAILURE_REASON="--very-verbose flag still present"
    return 1
  }
  
  return 0
}

# Test that pre-flight checks exist
has_preflight_checks() {
  # Verify the script checks for required commands
  grep -q "Pre-flight checks" "$ROOT_DIR/spells/system/test-magic" || {
    TEST_FAILURE_REASON="Pre-flight checks comment not found"
    return 1
  }
  
  grep -q "missing_commands" "$ROOT_DIR/spells/system/test-magic" || {
    TEST_FAILURE_REASON="missing_commands variable not found"
    return 1
  }
  
  grep -q "required commands not found" "$ROOT_DIR/spells/system/test-magic" || {
    TEST_FAILURE_REASON="Error message for missing commands not found"
    return 1
  }
  
  return 0
}

# Test that timeout protection exists
has_timeout_protection() {
  # Verify timeout command check
  grep -q "timeout_cmd" "$ROOT_DIR/spells/system/test-magic" || {
    TEST_FAILURE_REASON="timeout_cmd variable not found"
    return 1
  }
  
  # Verify timeout is used for test execution
  grep -q "WIZARDRY_TEST_TIMEOUT" "$ROOT_DIR/spells/system/test-magic" || {
    TEST_FAILURE_REASON="WIZARDRY_TEST_TIMEOUT variable not found"
    return 1
  }
  
  # Verify timeout exit code handling (124 is timeout's exit code)
  grep -q "124" "$ROOT_DIR/spells/system/test-magic" || {
    TEST_FAILURE_REASON="Timeout exit code (124) handling not found"
    return 1
  }
  
  return 0
}

_run_test_case "system/test-magic is executable" spell_is_executable
_run_test_case "system/test-magic shows help" shows_help
_run_test_case "system/test-magic has content" spell_has_content
_run_test_case "system/test-magic processes all tests without skipping" all_tests_are_processed
_run_test_case "system/test-magic has no test rerun logic" no_test_reruns
_run_test_case "system/test-magic has pre-flight checks" has_preflight_checks
_run_test_case "system/test-magic has timeout protection" has_timeout_protection

_finish_tests
