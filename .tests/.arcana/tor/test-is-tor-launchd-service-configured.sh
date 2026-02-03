#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/tor/is-tor-launchd-service-configured" ]
}

run_test_case "tor/is-tor-launchd-service-configured is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/tor/is-tor-launchd-service-configured" ]
}

run_test_case "tor/is-tor-launchd-service-configured has content" spell_has_content

shows_help() {
  run_spell spells/.arcana/tor/is-tor-launchd-service-configured --help
  true
}

run_test_case "is-tor-launchd-service-configured shows help" shows_help
finish_tests
