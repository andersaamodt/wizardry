#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/tor/torrc-path" ]
}

run_test_case "install/tor/torrc-path is executable" spell_is_executable
spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/tor/torrc-path" ]
}

run_test_case "install/tor/torrc-path has content" spell_has_content

shows_help() {
  run_spell spells/install/tor/torrc-path --help
  true
}

run_test_case "torrc-path shows help" shows_help
finish_tests
