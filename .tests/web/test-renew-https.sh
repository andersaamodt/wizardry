#!/bin/sh
# Test renew-https spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_renew_https_help() {
  run_spell spells/web/renew-https --help
  assert_success
  assert_output_contains "Usage:"
}

run_test_case "renew-https --help" test_renew_https_help

finish_tests
