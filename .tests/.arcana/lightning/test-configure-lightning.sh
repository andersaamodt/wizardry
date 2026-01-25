#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/lightning/configure-lightning" ]
}

run_test_case "lightning/configure-lightning is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/lightning/configure-lightning" ]
}

run_test_case "lightning/configure-lightning has content" spell_has_content

shows_help() {
  run_spell spells/.arcana/lightning/configure-lightning --help
  true
}

run_test_case "configure-lightning shows help" shows_help
finish_tests
