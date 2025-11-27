#!/bin/sh
# Test coverage for reload-ssh spell:
# - Shows usage with --help

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/cantrips/reload-ssh" --help
  assert_success || return 1
  assert_output_contains "Usage: reload-ssh" || return 1
}

run_test_case "reload-ssh shows usage text" test_help

finish_tests
