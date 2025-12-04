#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/system/test-magic" ]
}

shows_help() {
  run_spell spells/system/test-magic --help
  assert_success
  assert_output_contains "Usage:"
}

fails_for_unknown_flag() {
  run_spell spells/system/test-magic --unknown
  assert_failure
  assert_error_contains "unknown option"
}

rejects_missing_only_pattern() {
  run_spell spells/system/test-magic --only
  assert_failure
  assert_error_contains "requires a pattern"
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/system/test-magic" ]
}

run_test_case "system/test-magic is executable" spell_is_executable
run_test_case "system/test-magic shows help" shows_help
run_test_case "system/test-magic has content" spell_has_content
run_test_case "test-magic rejects unknown flags" fails_for_unknown_flag
run_test_case "test-magic requires a pattern for --only" rejects_missing_only_pattern

finish_tests
