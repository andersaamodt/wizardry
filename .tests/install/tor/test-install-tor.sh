#!/bin/sh
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/tor/install-tor" ]
}
run_test_case "install/tor/install-tor is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/tor/install-tor" ]
}
run_test_case "install/tor/install-tor has content" spell_has_content

shows_help() {
  run_spell spells/install/tor/install-tor --help
  true
}
run_test_case "install-tor shows help" shows_help

finish_tests
