#!/bin/sh
# Test coverage for stop-listening spell:
# - Shows usage with --help
# - Handles no listener running gracefully

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/mud/stop-listening" --help
  assert_success || return 1
  assert_output_contains "Usage: stop-listening" || return 1
}

test_no_listener_running() {
  tmpdir=$(make_tempdir)
  
  # Try to stop when nothing is running
  HOME="$tmpdir" run_spell "spells/mud/stop-listening"
  assert_success || return 1
  assert_output_contains "Not currently listening" || return 1
}

run_test_case "stop-listening shows usage text" test_help
run_test_case "stop-listening handles no listener gracefully" test_no_listener_running

finish_tests
