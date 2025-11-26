#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/bitcoin/is-bitcoin-installed" ]
}

run_test_case "install/bitcoin/is-bitcoin-installed is executable" spell_is_executable
spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/bitcoin/is-bitcoin-installed" ]
}

run_test_case "install/bitcoin/is-bitcoin-installed has content" spell_has_content
finish_tests
