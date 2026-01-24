#!/bin/sh
# Test coverage for stop-room-monitor spell:
# - Shows usage with --help
# - Handles no monitor running gracefully

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/mud/stop-room-monitor" --help
  assert_success || return 1
  assert_output_contains "Usage: stop-room-monitor" || return 1
}

test_no_monitor_running() {
  tmpdir=$(make_tempdir)
  
  # Try to stop when nothing is running
  HOME="$tmpdir" run_spell "spells/mud/stop-room-monitor"
  assert_success || return 1
  assert_output_contains "No room monitor is running" || return 1
}

run_test_case "stop-room-monitor shows usage text" test_help
run_test_case "stop-room-monitor handles no monitor gracefully" test_no_monitor_running

finish_tests
