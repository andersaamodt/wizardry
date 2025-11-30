#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/psi/list-contacts" ]
}

shows_help() {
  run_spell spells/psi/list-contacts --help
  assert_success
  assert_output_contains "Usage:"
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/psi/list-contacts" ]
}

run_test_case "psi/list-contacts is executable" spell_is_executable
run_test_case "list-contacts shows help" shows_help
run_test_case "psi/list-contacts has content" spell_has_content

finish_tests
