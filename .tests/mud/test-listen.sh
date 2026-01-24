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
  
  # Note: We can't actually test tail -f in a test, but we can verify
  # the spell would create the log file. We'll timeout quickly.
  # Use a subshell with timeout to avoid hanging
  (
    cd "$tmpdir" || exit 1
    timeout 1 "$ROOT_DIR/spells/mud/listen" 2>/dev/null || true
  ) &
  pid=$!
  sleep 0.5
  kill $pid 2>/dev/null || true
  wait $pid 2>/dev/null || true
  
  # Check log was created
  [ -f "$tmpdir/.room.log" ] || return 1
}

run_test_case "listen shows usage text" test_help
run_test_case "listen validates directory exists" test_nonexistent_directory
run_test_case "listen creates log if missing" test_creates_log_if_missing

finish_tests
