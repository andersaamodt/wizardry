#!/bin/sh
# Test coverage for listen spell:
# - Shows usage with --help
# - Validates directory exists
# - Creates log file if missing
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

test_creates_log_if_missing() {
  tmpdir=$(make_tempdir)
  
  # Check that log doesn't exist yet
  [ ! -f "$tmpdir/.room.log" ] || return 1
  
  # Run listen in background with a short timeout
  # Use sh -c with sleep and kill to avoid dependency on timeout command
  (
    cd "$tmpdir" || exit 1
    # Start listen in background
    "$ROOT_DIR/spells/mud/listen" >/dev/null 2>&1 &
    listen_pid=$!
    # Give it time to create the file
    sleep 1
    # Kill it
    kill "$listen_pid" 2>/dev/null || true
    wait "$listen_pid" 2>/dev/null || true
  )
  
  # Check log was created
  [ -f "$tmpdir/.room.log" ] || return 1
}

run_test_case "listen shows usage text" test_help
run_test_case "listen validates directory exists" test_nonexistent_directory
run_test_case "listen creates log if missing" test_creates_log_if_missing

finish_tests
