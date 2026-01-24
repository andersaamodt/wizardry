#!/bin/sh
# Test coverage for start-listening spell:
# - Shows usage with --help
# - Validates directory exists
# - Starts background process

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/mud/start-listening" --help
  assert_success || return 1
  assert_output_contains "Usage: start-listening" || return 1
}

test_nonexistent_directory() {
  run_spell "spells/mud/start-listening" /nonexistent/path
  assert_failure || return 1
  assert_error_contains "does not exist" || return 1
}

test_starts_listener() {
  tmpdir=$(make_tempdir)
  
  # Start listener in test directory
  HOME="$tmpdir" run_spell "spells/mud/start-listening" "$tmpdir"
  
  # Just check that it reported success
  assert_success || return 1
  assert_output_contains "Started listening" || return 1
}

run_test_case "start-listening shows usage text" test_help
run_test_case "start-listening validates directory exists" test_nonexistent_directory
run_test_case "start-listening starts background process" test_starts_listener

finish_tests
