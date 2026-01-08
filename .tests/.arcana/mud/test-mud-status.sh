#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/mud/mud-status" ]
}

run_test_case ".arcana/mud/mud-status is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/mud/mud-status" ]
}

run_test_case ".arcana/mud/mud-status has content" spell_has_content

test_mud_status_help() {
  run_spell "spells/.arcana/mud/mud-status" --help
  assert_success && assert_output_contains "Usage:"
}

run_test_case "mud-status prints usage" test_mud_status_help

finish_tests
