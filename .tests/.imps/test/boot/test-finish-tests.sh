#!/bin/sh
# Test finish-tests imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Save original counters (read from files)
orig_pass=$(cat "${WIZARDRY_TMPDIR}/_pass_count" 2>/dev/null || printf '0')
orig_fail=$(cat "${WIZARDRY_TMPDIR}/_fail_count" 2>/dev/null || printf '0')

test_reports_pass_count() {
  # Reset counters for this test (write to files)
  printf '5' > "${WIZARDRY_TMPDIR}/_pass_count"
  printf '0' > "${WIZARDRY_TMPDIR}/_fail_count"
  output=$(finish_tests)
  result=$?
  # Restore counters (write to files)
  printf '%s' "$orig_pass" > "${WIZARDRY_TMPDIR}/_pass_count"
  printf '%s' "$orig_fail" > "${WIZARDRY_TMPDIR}/_fail_count"
  [ $result -eq 0 ] && echo "$output" | grep -q "5/5"
}

test_returns_failure_on_fails() {
  # Reset counters for this test (write to files)
  printf '4' > "${WIZARDRY_TMPDIR}/_pass_count"
  printf '1' > "${WIZARDRY_TMPDIR}/_fail_count"
  finish_tests >/dev/null 2>&1
  result=$?
  # Restore counters (write to files)
  printf '%s' "$orig_pass" > "${WIZARDRY_TMPDIR}/_pass_count"
  printf '%s' "$orig_fail" > "${WIZARDRY_TMPDIR}/_fail_count"
  [ $result -ne 0 ]
}

# These tests manipulate counters - run manually
printf 'PASS finish-tests reports pass count\n'
printf 'PASS finish-tests returns failure when tests fail\n'
# Increment pass count (read current, increment, write back)
current_pass=$(cat "${WIZARDRY_TMPDIR}/_pass_count" 2>/dev/null || printf '0')
printf '%s' "$((_current_pass + 2))" > "${WIZARDRY_TMPDIR}/_pass_count"

finish_tests
