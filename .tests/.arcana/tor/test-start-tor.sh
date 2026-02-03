#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/tor/start-tor" ]
}

run_test_case "tor/start-tor is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/tor/start-tor" ]
}

run_test_case "tor/start-tor has content" spell_has_content

shows_help() {
  run_spell spells/.arcana/tor/start-tor --help
  true
}

run_test_case "start-tor shows help" shows_help
finish_tests
