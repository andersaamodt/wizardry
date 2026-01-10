#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/translocation/blink" --help
  assert_success
  assert_output_contains "Usage:"
  assert_output_contains "path"
  assert_output_contains "--depth"
  assert_output_contains "default: 5"
}

run_test_case "blink prints usage" test_help

finish_tests
