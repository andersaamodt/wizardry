#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/tor/torrc-path" ]
}

_run_test_case "install/tor/torrc-path is executable" spell_is_executable
spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/tor/torrc-path" ]
}

_run_test_case "install/tor/torrc-path has content" spell_has_content

shows_help() {
  _run_spell spells/.arcana/tor/torrc-path --help
  true
}

_run_test_case "torrc-path shows help" shows_help
_finish_tests
