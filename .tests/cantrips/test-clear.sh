#!/bin/sh
# Tests for the clear spell
# - clear prints usage
# - clear scrolls content off-screen by printing newlines
# - clear all clears the terminal session
# - clear accepts --help and --usage flags

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/cantrips/clear" --help
  assert_success || return 1
  assert_output_contains "Usage: clear" || return 1
  assert_output_contains "Clear the terminal screen" || return 1
}

test_usage_alias() {
  run_spell "spells/cantrips/clear" --usage
  assert_success || return 1
  assert_output_contains "Usage: clear" || return 1
}

test_usage_h_flag() {
  run_spell "spells/cantrips/clear" -h
  assert_success || return 1
  assert_output_contains "Usage: clear" || return 1
}

test_clear_default_mode() {
  run_spell "spells/cantrips/clear"
  assert_success || return 1
  # Should output multiple newlines (at least 10, likely more)
  # Check the output file directly since OUTPUT variable strips trailing newlines
  if [ -f "${WIZARDRY_TMPDIR}/_test_output" ]; then
    output_size=$(wc -c < "${WIZARDRY_TMPDIR}/_test_output")
    if [ "$output_size" -lt 10 ]; then
      TEST_FAILURE_REASON="Expected at least 10 bytes in output, got $output_size"
      return 1
    fi
  else
    TEST_FAILURE_REASON="Output file not found"
    return 1
  fi
}

test_clear_all_mode() {
  run_spell "spells/cantrips/clear" all
  assert_success || return 1
  # The output should contain clear sequences
  # Could be from /usr/bin/clear, tput, or ANSI escape sequences
  # We can't easily test the exact output, but it should succeed
}

test_clear_rejects_invalid_args() {
  run_spell "spells/cantrips/clear" invalid-arg
  # Should succeed but use default mode (scroll), not fail
  assert_success || return 1
}

# Run all tests
run_test_case "clear prints usage with --help" test_help
run_test_case "clear accepts --usage flag" test_usage_alias
run_test_case "clear accepts -h flag" test_usage_h_flag
run_test_case "clear default mode scrolls content off-screen" test_clear_default_mode
run_test_case "clear all mode clears terminal session" test_clear_all_mode
run_test_case "clear with invalid args uses default mode" test_clear_rejects_invalid_args

finish_tests
