#!/bin/sh
# Test stop-site spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_stop_site_help() {
  run_spell spells/web/stop-site --help
  assert_success
  assert_output_contains "Usage:"
}

run_test_case "stop-site --help" test_stop_site_help

finish_tests
