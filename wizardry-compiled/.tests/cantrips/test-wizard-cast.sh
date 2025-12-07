#!/bin/sh
# COMPILED_UNSUPPORTED: requires full wizardry environment
# Test coverage for wizard-cast spell:
# - Shows usage with --help
# - Requires command argument
# - Executes the given command

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/cantrips/wizard-cast" --help
  _assert_success || return 1
  _assert_output_contains "Usage: wizard-cast" || return 1
}

test_requires_argument() {
  _run_spell "spells/cantrips/wizard-cast"
  _assert_failure || return 1
  _assert_error_contains "command required" || return 1
}

test_executes_command() {
  _run_spell "spells/cantrips/wizard-cast" echo "hello"
  _assert_success || return 1
  _assert_output_contains "hello" || return 1
}

_run_test_case "wizard-cast shows usage text" test_help
_run_test_case "wizard-cast requires command argument" test_requires_argument
_run_test_case "wizard-cast executes the command" test_executes_command

_finish_tests
