#!/bin/sh
# Test disable-https spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_disable_https_help() {
  run_spell spells/web/disable-https --help
  assert_success
  assert_output_contains "Usage:"
}

run_test_case "disable-https --help" test_disable_https_help

finish_tests
