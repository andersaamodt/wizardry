#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/contacts/list-contacts" ]
}

shows_help() {
  run_spell spells/contacts/list-contacts --help
  assert_success
  assert_output_contains "Usage:"
}

run_test_case "contacts/list-contacts is executable" spell_is_executable
run_test_case "list-contacts shows help" shows_help

finish_tests
