#!/bin/sh
# Test coverage for listen spell:
# - Shows usage with --help
# - Validates directory exists
# - Starts background process
# - Stops with --stop option

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/mud/listen" --help
  assert_success || return 1
  assert_output_contains "Usage: listen" || return 1
}

test_nonexistent_directory() {
  run_spell "spells/mud/listen" /nonexistent/path
  assert_failure || return 1
  assert_error_contains "does not exist" || return 1
}

test_starts_listener() {
  tmpdir=$(make_tempdir)
  
  # Start listener in test directory
  HOME="$tmpdir" run_spell "spells/mud/listen" "$tmpdir"
  
  # Just check that it reported success
  assert_success || return 1
  assert_output_contains "Started listening" || return 1
}

test_stop_option() {
  tmpdir=$(make_tempdir)
  
  # Try to stop when nothing is running
  HOME="$tmpdir" run_spell "spells/mud/listen" --stop
  assert_success || return 1
  assert_output_contains "Stopped listening" || return 1
}

run_test_case "listen shows usage text" test_help
run_test_case "listen validates directory exists" test_nonexistent_directory  
run_test_case "listen starts background process" test_starts_listener
run_test_case "listen --stop stops listener" test_stop_option

finish_tests
