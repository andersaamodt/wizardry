#!/bin/sh
# Test coverage for restart-ssh spell:
# - Shows usage with --help

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/cantrips/restart-ssh" --help
  assert_success || return 1
  assert_output_contains "Usage: restart-ssh" || return 1
}

run_test_case "restart-ssh shows usage text" test_help

finish_tests
