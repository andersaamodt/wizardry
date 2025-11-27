#!/bin/sh
# Test coverage for wizard-cast spell:
# - Shows usage with --help
# - Requires command argument
# - Executes the given command

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/cantrips/wizard-cast" --help
  assert_success || return 1
  assert_output_contains "Usage: wizard-cast" || return 1
}

test_requires_argument() {
  run_spell "spells/cantrips/wizard-cast"
  assert_failure || return 1
  assert_error_contains "command required" || return 1
}

test_executes_command() {
  run_spell "spells/cantrips/wizard-cast" echo "hello"
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

run_test_case "wizard-cast shows usage text" test_help
run_test_case "wizard-cast requires command argument" test_requires_argument
run_test_case "wizard-cast executes the command" test_executes_command

finish_tests
