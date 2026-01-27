#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/core/install-pkgin" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "pkgin" || return 1
}

run_test_case "install-pkgin shows help" test_help
finish_tests
