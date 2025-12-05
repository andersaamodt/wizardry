#!/bin/sh
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

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
