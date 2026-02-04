#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/tor/is-tor-daemon-enabled" ]
}

run_test_case "tor/is-tor-daemon-enabled is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/tor/is-tor-daemon-enabled" ]
}

run_test_case "tor/is-tor-daemon-enabled has content" spell_has_content

shows_help() {
  run_spell spells/.arcana/tor/is-tor-daemon-enabled --help
  true
}

run_test_case "is-tor-daemon-enabled shows help" shows_help
finish_tests
