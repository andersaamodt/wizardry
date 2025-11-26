#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/tor/setup-tor" ]
}

run_test_case "install/tor/setup-tor is executable" spell_is_executable
spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/tor/setup-tor" ]
}

run_test_case "install/tor/setup-tor has content" spell_has_content

shows_help() {
  run_spell spells/install/tor/setup-tor --help
  true
}

run_test_case "setup-tor shows help" shows_help
finish_tests
