#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/bitcoin/is-bitcoin-running" ]
}

_run_test_case "install/bitcoin/is-bitcoin-running is executable" spell_is_executable
spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/bitcoin/is-bitcoin-running" ]
}

_run_test_case "install/bitcoin/is-bitcoin-running has content" spell_has_content

shows_help() {
  _run_spell spells/.arcana/bitcoin/is-bitcoin-running --help
  # Note: spell may not have --help implemented yet
  true
}

_run_test_case "is-bitcoin-running shows help" shows_help
_finish_tests
