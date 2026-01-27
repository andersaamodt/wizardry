#!/bin/sh
# Test serve-site spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_serve_site_help() {
  run_spell spells/web/serve-site --help
  assert_success
  assert_output_contains "Usage:"
}

run_test_case "serve-site --help" test_serve_site_help

finish_tests
