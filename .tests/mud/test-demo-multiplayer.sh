#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/mud/demo-multiplayer" ]
}

run_test_case "demo-multiplayer is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/mud/demo-multiplayer" ]
}

run_test_case "demo-multiplayer has content" spell_has_content

shows_help() {
  run_spell "spells/mud/demo-multiplayer" --help
  assert_success || return 1
  assert_output_contains "Usage:" || assert_output_contains "demo" || return 1
}

run_test_case "demo-multiplayer shows help" shows_help

finish_tests
