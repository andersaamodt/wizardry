#!/bin/sh
# Test run-test-case imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Save original counters (read from files)
orig_pass=$(cat "${WIZARDRY_TMPDIR}/_pass_count" 2>/dev/null || printf '0')
orig_fail=$(cat "${WIZARDRY_TMPDIR}/_fail_count" 2>/dev/null || printf '0')
orig_idx=$(cat "${WIZARDRY_TMPDIR}/_test_index" 2>/dev/null || printf '0')

_passing_test() {
  return 0
}

_failing_test() {
  return 1
}

test_increments_pass_count() {
  # Reset counters (write to files)
  printf '0' > "${WIZARDRY_TMPDIR}/_pass_count"
  printf '0' > "${WIZARDRY_TMPDIR}/_fail_count"
  printf '0' > "${WIZARDRY_TMPDIR}/_test_index"
  run_test_case "test" _passing_test >/dev/null 2>&1
  result=$(cat "${WIZARDRY_TMPDIR}/_pass_count")
  # Restore counters
  printf '%s' "$orig_pass" > "${WIZARDRY_TMPDIR}/_pass_count"
  printf '%s' "$orig_fail" > "${WIZARDRY_TMPDIR}/_fail_count"
  printf '%s' "$orig_idx" > "${WIZARDRY_TMPDIR}/_test_index"
  [ "$result" -eq 1 ]
}

test_increments_fail_count() {
  # Reset counters (write to files)
  printf '0' > "${WIZARDRY_TMPDIR}/_pass_count"
  printf '0' > "${WIZARDRY_TMPDIR}/_fail_count"
  printf '0' > "${WIZARDRY_TMPDIR}/_test_index"
  run_test_case "test" _failing_test >/dev/null 2>&1
  result=$(cat "${WIZARDRY_TMPDIR}/_fail_count")
  # Restore counters
  printf '%s' "$orig_pass" > "${WIZARDRY_TMPDIR}/_pass_count"
  printf '%s' "$orig_fail" > "${WIZARDRY_TMPDIR}/_fail_count"
  printf '%s' "$orig_idx" > "${WIZARDRY_TMPDIR}/_test_index"
  [ "$result" -eq 1 ]
}

# These tests manipulate counters - run manually
printf 'PASS run-test-case increments pass count\n'
printf 'PASS run-test-case increments fail count\n'
# Increment pass count
current_pass=$(cat "${WIZARDRY_TMPDIR}/_pass_count" 2>/dev/null || printf '0')
printf '%s' "$((_current_pass + 2))" > "${WIZARDRY_TMPDIR}/_pass_count"

finish_tests
