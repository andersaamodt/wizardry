#!/bin/sh
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/tor/tor-menu" ]
}

run_test_case "install/tor/tor-menu is executable" spell_is_executable
spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/tor/tor-menu" ]
}

run_test_case "install/tor/tor-menu has content" spell_has_content

test_shows_help() {
  run_cmd "$ROOT_DIR/spells/install/tor/tor-menu" --help
  assert_success
  assert_output_contains "Usage: tor-menu"
}

run_test_case "tor-menu --help shows usage" test_shows_help

finish_tests
