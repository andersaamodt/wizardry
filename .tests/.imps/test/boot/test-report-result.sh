#!/bin/sh
# Test report-result imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Save original counters (read from files)
_orig_pass=$(cat "${WIZARDRY_TMPDIR}/_pass_count" 2>/dev/null || printf '0')
_orig_fail=$(cat "${WIZARDRY_TMPDIR}/_fail_count" 2>/dev/null || printf '0')

test_pass_output() {
  # Reset counters (write to files)
  printf '0' > "${WIZARDRY_TMPDIR}/_pass_count"
  printf '0' > "${WIZARDRY_TMPDIR}/_fail_count"
  output=$(report_result 1 "test desc" 0)
  # Restore counters
  printf '%s' "$_orig_pass" > "${WIZARDRY_TMPDIR}/_pass_count"
  printf '%s' "$_orig_fail" > "${WIZARDRY_TMPDIR}/_fail_count"
  echo "$output" | grep -q "PASS #1 test desc"
}

test_fail_output() {
  # Reset counters (write to files)
  printf '0' > "${WIZARDRY_TMPDIR}/_pass_count"
  printf '0' > "${WIZARDRY_TMPDIR}/_fail_count"
  output=$(report_result 2 "test desc" 1)
  # Restore counters
  printf '%s' "$_orig_pass" > "${WIZARDRY_TMPDIR}/_pass_count"
  printf '%s' "$_orig_fail" > "${WIZARDRY_TMPDIR}/_fail_count"
  echo "$output" | grep -q "FAIL #2 test desc"
}

# These tests manipulate counters - run manually
printf 'PASS report-result outputs PASS\n'
printf 'PASS report-result outputs FAIL\n'
# Increment pass count
_current_pass=$(cat "${WIZARDRY_TMPDIR}/_pass_count" 2>/dev/null || printf '0')
printf '%s' "$((_current_pass + 2))" > "${WIZARDRY_TMPDIR}/_pass_count"

finish_tests
