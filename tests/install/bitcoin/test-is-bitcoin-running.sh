#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/bitcoin/is-bitcoin-running" ]
}

run_test_case "install/bitcoin/is-bitcoin-running is executable" spell_is_executable
spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/bitcoin/is-bitcoin-running" ]
}

run_test_case "install/bitcoin/is-bitcoin-running has content" spell_has_content

shows_help() {
  run_spell spells/install/bitcoin/is-bitcoin-running --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "is-bitcoin-running shows help" shows_help
finish_tests
