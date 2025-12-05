#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/system/test-magic" ]
}

shows_help() {
  run_spell spells/system/test-magic --help
  assert_success
  assert_output_contains "Usage:"
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/system/test-magic" ]
}

run_test_case "system/test-magic is executable" spell_is_executable
run_test_case "system/test-magic shows help" shows_help
run_test_case "system/test-magic has content" spell_has_content

finish_tests
