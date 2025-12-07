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
  _run_spell spells/system/test-magic --help
  _assert_success
  _assert_output_contains "Usage:"
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/system/test-magic" ]
}

_run_test_case "system/test-magic is executable" spell_is_executable
_run_test_case "system/test-magic shows help" shows_help
_run_test_case "system/test-magic has content" spell_has_content

_finish_tests
