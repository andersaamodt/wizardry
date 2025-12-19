#!/bin/sh
# TEMPORARY TEST: Verify that unit test PASS/FAIL lines are output immediately
# as each subtest completes, not buffered and dumped all at once.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_verify_immediate_output() {
  tmpdir=$(_make_tempdir)
  testfile="$tmpdir/timing-test.sh"
  
  # Create a test file with 5 subtests that each sleep for 0.3 seconds
  {
    printf '#!/bin/sh\n'
    printf '. "%s/spells/.imps/test/test-bootstrap"\n\n' "$ROOT_DIR"
    cat <<'INNER'
test_1() { sleep 0.3; _run_cmd true; _assert_success; }
test_2() { sleep 0.3; _run_cmd true; _assert_success; }
test_3() { sleep 0.3; _run_cmd true; _assert_success; }
test_4() { sleep 0.3; _run_cmd true; _assert_success; }
test_5() { sleep 0.3; _run_cmd true; _assert_success; }

_run_test_case "test 1" test_1
_run_test_case "test 2" test_2
_run_test_case "test 3" test_3
_run_test_case "test 4" test_4
_run_test_case "test 5" test_5
_finish_tests
INNER
  } > "$testfile"
  chmod +x "$testfile"
  
  # Run test and capture output with timestamps
  output_file="$tmpdir/output.txt"
  timestamp_script="$tmpdir/ts.sh"
  
  cat > "$timestamp_script" <<'TS'
#!/bin/sh
while IFS= read -r line; do
  printf '%s|%s\n' "$(date +%s.%N)" "$line"
done
TS
  chmod +x "$timestamp_script"
  
  # Run with stdbuf if available to force line buffering
  if command -v stdbuf >/dev/null 2>&1; then
    stdbuf -oL "$testfile" 2>&1 | "$timestamp_script" > "$output_file"
  else
    "$testfile" 2>&1 | "$timestamp_script" > "$output_file"
  fi
  
  # Extract PASS line timestamps
  pass_times=$(grep '|PASS ' "$output_file" | cut -d'|' -f1)
  pass_count=$(printf '%s\n' "$pass_times" | grep -c '^' || echo "0")
  
  if [ "$pass_count" -ne 5 ]; then
    TEST_FAILURE_REASON="expected 5 PASS lines, got $pass_count"
    return 1
  fi
  
  # Check timing spread
  first_time=$(printf '%s\n' "$pass_times" | head -1)
  last_time=$(printf '%s\n' "$pass_times" | tail -1)
  time_diff=$(awk "BEGIN {print $last_time - $first_time}")
  
  # Should be at least 1 second for proper streaming
  is_progressive=$(awk "BEGIN {print ($time_diff >= 1.0) ? \"yes\" : \"no\"}")
  
  if [ "$is_progressive" != "yes" ]; then
    TEST_FAILURE_REASON="PASS lines appeared too quickly (${time_diff}s), indicating buffered output"
    return 1
  fi
  
  # Check for at least 3 distinct time buckets (0.1s resolution)
  buckets=$(printf '%s\n' "$pass_times" | awk '{print int($1 * 10)}' | sort -u | wc -l)
  
  if [ "$buckets" -lt 3 ]; then
    TEST_FAILURE_REASON="PASS lines clustered in $buckets time buckets, expected at least 3"
    return 1
  fi
  
  return 0
}

_run_test_case "PASS/FAIL lines output immediately (not buffered)" test_verify_immediate_output
_finish_tests
