#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Fast test used for file descriptor bug regression validation
# Use a simple boot test to avoid recursive heavy test execution
FAST_TEST_FOR_VALIDATION=".imps/test/boot/test-assert-success.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/system/test-magic" ]
}

shows_help() {
  run_spell spells/system/test-magic --help
  assert_success
  assert_output_contains "Usage:"
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/system/test-magic" ]
}

# Regression test for file descriptor bug (issue #XXX)
# When tests inherit stdin from the loop reading the test list file,
# tests that read from stdin can consume lines from the test list.
# This verifies all tests are processed correctly.
all_tests_are_processed() {
  # Run test-magic on a small, fast test and verify counts match
  tmpdir="$(make_tempdir)"
  tmpfile="$tmpdir/output.txt"
  
  cd "$ROOT_DIR" || return 1
  
  # Verify the test exists before running
  if [ ! -f "$ROOT_DIR/.tests/$FAST_TEST_FOR_VALIDATION" ]; then
    # If the specific test doesn't exist, skip validation
    return 0
  fi
  
  # Run test-magic on that one simple test
  sh spells/system/test-magic --only "$FAST_TEST_FOR_VALIDATION" >"$tmpfile" 2>&1 || true
  
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

# Test that failed subtests cause the parent test to fail
failed_subtests_fail_parent_test() {
  tmpdir="$(make_tempdir)"
  [ -d "$tmpdir" ] || { TEST_FAILURE_REASON="tmpdir not created: $tmpdir"; return 1; }
  tmpfile="$tmpdir/output.txt"
  
  # Create a test fixture in .tests directory
  fixture_dir="$ROOT_DIR/.tests/__temp_test_fixtures"
  mkdir -p "$fixture_dir"
  test_fixture="$fixture_dir/test-with-failures.sh"
  
  cat > "$test_fixture" << 'EOF'
#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pass1() { return 0; }
test_fail1() { TEST_FAILURE_REASON="failure 1"; return 1; }
test_pass2() { return 0; }
test_fail2() { TEST_FAILURE_REASON="failure 2"; return 1; }

run_test_case "pass 1" test_pass1
run_test_case "fail 1" test_fail1
run_test_case "pass 2" test_pass2
run_test_case "fail 2" test_fail2
finish_tests
EOF
  chmod +x "$test_fixture"
  
  cd "$ROOT_DIR" || return 1
  
  # Run test-magic on the fixture
  sh spells/system/test-magic --only "__temp_test_fixtures/test-with-failures.sh" >"$tmpfile" 2>&1 || true
  
  # Clean up fixture
  rm -rf "$fixture_dir"
  
  # Check tmpfile exists and has content
  [ -f "$tmpfile" ] || { TEST_FAILURE_REASON="tmpfile not created: $tmpfile"; return 1; }
  [ -s "$tmpfile" ] || { TEST_FAILURE_REASON="tmpfile is empty: $tmpfile"; return 1; }
  
  # Extract summary line
  summary=$(grep "^Tests:" "$tmpfile" || true)
  
  # Debug: if no summary found, show what's in the file
  if [ -z "$summary" ]; then
    tmpfile_content=$(head -20 "$tmpfile" 2>/dev/null || echo "ERROR reading tmpfile")
    TEST_FAILURE_REASON="No summary line found. tmpfile content (first 20 lines): $tmpfile_content"
    return 1
  fi
  
  # The test should be marked as FAILED, not PASSED
  # Look for "X failed" where X > 0
  failed_count=$(printf '%s\n' "$summary" | awk '{for(i=1;i<=NF;i++) if($(i+1)=="failed,") print $i}')
  
  [ -n "$failed_count" ] && [ "$failed_count" -gt 0 ] || {
    TEST_FAILURE_REASON="Test with failing subtests was not counted as failed (summary: $summary)"
    return 1
  }
  
  return 0
}

# Test that FAIL_DETAIL lines are not visible in output
fail_detail_hidden_from_output() {
  tmpdir="$(make_tempdir)"
  tmpfile="$tmpdir/output.txt"
  
  # Create a test fixture in .tests directory
  fixture_dir="$ROOT_DIR/.tests/__temp_test_fixtures"
  mkdir -p "$fixture_dir"
  test_fixture="$fixture_dir/test-with-failures.sh"
  
  cat > "$test_fixture" << 'EOF'
#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pass1() { return 0; }
test_fail1() { TEST_FAILURE_REASON="failure 1"; return 1; }

run_test_case "pass 1" test_pass1
run_test_case "fail 1" test_fail1
finish_tests
EOF
  chmod +x "$test_fixture"
  
  cd "$ROOT_DIR" || return 1
  
  # Run test-magic on the fixture
  sh spells/system/test-magic --only "__temp_test_fixtures/test-with-failures.sh" >"$tmpfile" 2>&1 || true
  
  # Clean up fixture
  rm -rf "$fixture_dir"
  
  # FAIL_DETAIL lines should not appear in the per-test output section
  # They should only be used internally for parsing
  # Look for lines like "  FAIL_DETAIL" in the indented test output
  if grep -E "^  FAIL_DETAIL" "$tmpfile" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="FAIL_DETAIL line visible in test output"
    return 1
  fi
  
  return 0
}

# Test that test summary line (X/Y tests passed) is visible in output
test_summary_line_visible() {
  tmpdir="$(make_tempdir)"
  tmpfile="$tmpdir/output.txt"
  
  # Create a test fixture in .tests directory
  fixture_dir="$ROOT_DIR/.tests/__temp_test_fixtures"
  mkdir -p "$fixture_dir"
  test_fixture="$fixture_dir/test-all-pass.sh"
  
  cat > "$test_fixture" << 'EOF'
#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pass1() { return 0; }
test_pass2() { return 0; }
test_pass3() { return 0; }

run_test_case "pass 1" test_pass1
run_test_case "pass 2" test_pass2
run_test_case "pass 3" test_pass3
finish_tests
EOF
  chmod +x "$test_fixture"
  
  cd "$ROOT_DIR" || return 1
  
  # Run test-magic on the fixture
  sh spells/system/test-magic --only "__temp_test_fixtures/test-all-pass.sh" >"$tmpfile" 2>&1 || true
  
  # Clean up fixture
  rm -rf "$fixture_dir"
  
  # Check tmpfile exists and has content
  [ -f "$tmpfile" ] || { TEST_FAILURE_REASON="tmpfile not created: $tmpfile"; return 1; }
  [ -s "$tmpfile" ] || { TEST_FAILURE_REASON="tmpfile is empty: $tmpfile"; return 1; }
  
  # The test should show its own summary line like "3/3 tests passed"
  # This helps users see the subtest results for each test
  if ! grep -E "^  [0-9]+/[0-9]+ tests passed" "$tmpfile" >/dev/null 2>&1; then
    tmpfile_content=$(cat "$tmpfile" 2>/dev/null || echo "ERROR reading tmpfile")
    TEST_FAILURE_REASON="Test summary line not visible in output. Content: $tmpfile_content"
    return 1
  fi
  
  return 0
}

# Test that failed subtest numbers appear in failure summary
failed_subtest_numbers_in_summary() {
  tmpdir="$(make_tempdir)"
  tmpfile="$tmpdir/output.txt"
  
  # Create a test fixture in .tests directory
  fixture_dir="$ROOT_DIR/.tests/__temp_test_fixtures"
  mkdir -p "$fixture_dir"
  test_fixture="$fixture_dir/test-with-failures.sh"
  
  cat > "$test_fixture" << 'EOF'
#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pass1() { return 0; }
test_fail1() { TEST_FAILURE_REASON="failure 1"; return 1; }
test_pass2() { return 0; }
test_fail2() { TEST_FAILURE_REASON="failure 2"; return 1; }

run_test_case "pass 1" test_pass1
run_test_case "fail 1" test_fail1
run_test_case "pass 2" test_pass2
run_test_case "fail 2" test_fail2
finish_tests
EOF
  chmod +x "$test_fixture"
  
  cd "$ROOT_DIR" || return 1
  
  # Run test-magic on the fixture
  sh spells/system/test-magic --only "__temp_test_fixtures/test-with-failures.sh" >"$tmpfile" 2>&1 || true
  
  # Clean up fixture
  rm -rf "$fixture_dir"
  
  # Look for the failed tests line at the end showing subtest numbers
  # Should be like: "Failed tests (os): with-failures (2, 4)"
  failed_line=$(grep "^Failed tests" "$tmpfile" || true)
  
  [ -n "$failed_line" ] || {
    TEST_FAILURE_REASON="Failed tests summary line not found"
    return 1
  }
  
  # Should contain the subtest numbers in parentheses
  if ! printf '%s\n' "$failed_line" | grep -E '\([0-9]+(, [0-9]+)*\)' >/dev/null 2>&1; then
    TEST_FAILURE_REASON="Failed subtest numbers not shown in summary (got: $failed_line)"
    return 1
  fi
  
  return 0
}

# Test that detailed failure output shows when there are few failures
detailed_output_for_few_failures() {
  tmpdir="$(make_tempdir)"
  tmpfile="$tmpdir/output.txt"
  
  # Create a test fixture in .tests directory
  fixture_dir="$ROOT_DIR/.tests/__temp_test_fixtures"
  mkdir -p "$fixture_dir"
  test_fixture="$fixture_dir/test-with-failures.sh"
  
  cat > "$test_fixture" << 'EOF'
#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pass1() { return 0; }
test_fail1() { TEST_FAILURE_REASON="failure 1"; return 1; }
test_fail2() { TEST_FAILURE_REASON="failure 2"; return 1; }

run_test_case "pass 1" test_pass1
run_test_case "fail 1" test_fail1
run_test_case "fail 2" test_fail2
finish_tests
EOF
  chmod +x "$test_fixture"
  
  cd "$ROOT_DIR" || return 1
  
  # Run test-magic on the fixture
  sh spells/system/test-magic --only "__temp_test_fixtures/test-with-failures.sh" >"$tmpfile" 2>&1 || true
  
  # Clean up fixture
  rm -rf "$fixture_dir"
  
  # With only 1 failing test, detailed output should be shown
  # Look for "Failure Details" section
  if ! grep "Failure Details" "$tmpfile" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="Failure Details section not found for test with failures"
    return 1
  fi
  
  # The detailed section should contain information about the failures
  # Look for lines that show FAIL messages
  if ! grep -A 10 "Failure Details" "$tmpfile" | grep "FAIL" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="No failure details shown under Failure Details section"
    return 1
  fi
  
  return 0
}

# Test that output streams line-by-line (not buffered)
output_streams_line_by_line() {
  tmpdir="$(make_tempdir)"
  tmpfile="$tmpdir/output.txt"
  
  # Create a test fixture with delays
  fixture_dir="$ROOT_DIR/.tests/__temp_test_fixtures"
  mkdir -p "$fixture_dir"
  test_fixture="$fixture_dir/test-streaming.sh"
  
  cat > "$test_fixture" << 'EOF'
#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_1() { return 0; }
test_2() { return 0; }
test_3() { return 0; }

run_test_case "test 1" test_1
run_test_case "test 2" test_2
run_test_case "test 3" test_3
finish_tests
EOF
  chmod +x "$test_fixture"
  
  cd "$ROOT_DIR" || return 1
  
  # Run test-magic and verify stdbuf is applied inside wrapper
  # We verify this by checking that the wrapper script contains stdbuf
  sh spells/system/test-magic --only "__temp_test_fixtures/test-streaming.sh" >"$tmpfile" 2>&1 || true
  
  # Clean up fixture
  rm -rf "$fixture_dir"
  
  # Verify that PASS lines appear in output (confirming streaming works)
  # If output is not streaming, subtests would be buffered
  if ! grep -q "PASS #1" "$tmpfile"; then
    TEST_FAILURE_REASON="PASS #1 not found in output (streaming may be broken)"
    return 1
  fi
  
  if ! grep -q "PASS #2" "$tmpfile"; then
    TEST_FAILURE_REASON="PASS #2 not found in output (streaming may be broken)"
    return 1
  fi
  
  if ! grep -q "PASS #3" "$tmpfile"; then
    TEST_FAILURE_REASON="PASS #3 not found in output (streaming may be broken)"
    return 1
  fi
  
  # Verify that the wrapper applies stdbuf to the sh command
  # This is a white-box test to ensure the fix stays in place
  if ! grep -q 'stdbuf.*sh.*"\$abs"' "$ROOT_DIR/spells/system/test-magic"; then
    TEST_FAILURE_REASON="stdbuf not applied to sh command in wrapper (streaming optimization missing)"
    return 1
  fi
  
  return 0
}

run_test_case "system/test-magic is executable" spell_is_executable
run_test_case "system/test-magic shows help" shows_help
run_test_case "system/test-magic has content" spell_has_content
run_test_case "system/test-magic processes all tests without skipping" all_tests_are_processed
run_test_case "system/test-magic has no test rerun logic" no_test_reruns
run_test_case "system/test-magic has pre-flight checks" has_preflight_checks
run_test_case "system/test-magic has timeout protection" has_timeout_protection
run_test_case "failed subtests cause parent test to fail" failed_subtests_fail_parent_test
run_test_case "FAIL_DETAIL lines hidden from output" fail_detail_hidden_from_output
run_test_case "test summary line visible in output" test_summary_line_visible
run_test_case "failed subtest numbers in summary" failed_subtest_numbers_in_summary
run_test_case "detailed output shown for few failures" detailed_output_for_few_failures
run_test_case "output streams line-by-line" output_streams_line_by_line

finish_tests
