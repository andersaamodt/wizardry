#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/tor/repair-tor-permissions" ]
}

_run_test_case "install/tor/repair-tor-permissions is executable" spell_is_executable
spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/tor/repair-tor-permissions" ]
}

_run_test_case "install/tor/repair-tor-permissions has content" spell_has_content

shows_help() {
  _run_spell spells/install/tor/repair-tor-permissions --help
  true
}

_run_test_case "repair-tor-permissions shows help" shows_help
_finish_tests
