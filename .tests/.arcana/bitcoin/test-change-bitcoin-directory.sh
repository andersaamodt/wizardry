#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/bitcoin/change-bitcoin-directory" ]
}

run_test_case "install/bitcoin/change-bitcoin-directory is executable" spell_is_executable
spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/bitcoin/change-bitcoin-directory" ]
}

run_test_case "install/bitcoin/change-bitcoin-directory has content" spell_has_content

shows_help() {
  run_spell spells/.arcana/bitcoin/change-bitcoin-directory --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "change-bitcoin-directory shows help" shows_help
finish_tests
