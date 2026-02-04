#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/web/toggle-site-tor-hosting" ]
}

run_test_case "web/toggle-site-tor-hosting is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/web/toggle-site-tor-hosting" ]
}

run_test_case "web/toggle-site-tor-hosting has content" spell_has_content

shows_help() {
  run_spell spells/web/toggle-site-tor-hosting --help
  true
}

run_test_case "toggle-site-tor-hosting shows help" shows_help
finish_tests
