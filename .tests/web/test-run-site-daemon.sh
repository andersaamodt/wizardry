#!/bin/sh
# Tests for run-site-daemon spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_run_site_daemon_help() {
  run_spell spells/web/run-site-daemon --help
  assert_success
  assert_output_contains "Usage: run-site-daemon"
}

run_test_case "run-site-daemon --help works" test_run_site_daemon_help

finish_tests
