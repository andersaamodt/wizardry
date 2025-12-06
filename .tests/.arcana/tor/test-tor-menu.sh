#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/tor/tor-menu" ]
}

_run_test_case "install/tor/tor-menu is executable" spell_is_executable
spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/tor/tor-menu" ]
}

_run_test_case "install/tor/tor-menu has content" spell_has_content

test_shows_help() {
  _run_cmd "$ROOT_DIR/spells/.arcana/tor/tor-menu" --help
  _assert_success
  _assert_output_contains "Usage: tor-menu"
}

_run_test_case "tor-menu --help shows usage" test_shows_help

_finish_tests
