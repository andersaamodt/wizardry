#!/bin/sh
# Test coverage for listen spell:
# - Shows usage with --help
# - Validates directory exists
# - Fails if no log file exists (doesn't create it)
# - Requires tail command

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

test_fails_if_no_log() {
  tmpdir=$(make_tempdir)
  
  # Check that log doesn't exist yet
  [ ! -f "$tmpdir/.room.log" ] || return 1
  
  # Run listen and expect it to fail
  run_spell "spells/mud/listen" "$tmpdir"
  assert_failure || return 1
  assert_error_contains "no activity in this room yet" || return 1
}

run_test_case "listen shows usage text" test_help
run_test_case "listen validates directory exists" test_nonexistent_directory
run_test_case "listen fails if no log exists" test_fails_if_no_log

finish_tests
