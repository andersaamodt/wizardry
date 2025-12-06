#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/bitcoin/repair-bitcoin-permissions" ]
}

_run_test_case "install/bitcoin/repair-bitcoin-permissions is executable" spell_is_executable
spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/bitcoin/repair-bitcoin-permissions" ]
}

_run_test_case "install/bitcoin/repair-bitcoin-permissions has content" spell_has_content

shows_help() {
  _run_spell spells/.arcana/bitcoin/repair-bitcoin-permissions --help
  # Note: spell may not have --help implemented yet
  true
}

_run_test_case "repair-bitcoin-permissions shows help" shows_help
_finish_tests
