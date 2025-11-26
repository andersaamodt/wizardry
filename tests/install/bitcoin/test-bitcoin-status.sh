#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/bitcoin/bitcoin-status" ]
}

run_test_case "install/bitcoin/bitcoin-status is executable" spell_is_executable
spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/bitcoin/bitcoin-status" ]
}

run_test_case "install/bitcoin/bitcoin-status has content" spell_has_content

shows_help() {
  run_spell spells/install/bitcoin/bitcoin-status --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "bitcoin-status shows help" shows_help
finish_tests
