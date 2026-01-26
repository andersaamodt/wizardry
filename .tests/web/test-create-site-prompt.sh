#!/bin/sh
# Test create-site-prompt spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_create_site_prompt_help() {
  run_spell spells/web/create-site-prompt --help
  assert_success
  assert_output_contains "Usage:"
}

run_test_case "create-site-prompt --help" test_create_site_prompt_help

finish_tests
