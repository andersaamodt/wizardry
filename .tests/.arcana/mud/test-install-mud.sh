#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/mud/install-mud" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/mud/install-mud" ]
}

_run_test_case "install/mud/install-mud is executable" spell_is_executable
_run_test_case "install/mud/install-mud has content" spell_has_content

shows_help() {
  _run_spell spells/.arcana/mud/install-mud --help
  true
}

_run_test_case "install-mud shows help" shows_help
_finish_tests
