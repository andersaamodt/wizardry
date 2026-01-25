#!/bin/sh
set -eu

# Locate repo root
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/web-wizardry/uninstall-fcgiwrap" ]
}
run_test_case "install/web-wizardry/uninstall-fcgiwrap is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/web-wizardry/uninstall-fcgiwrap" ]
}
run_test_case "install/web-wizardry/uninstall-fcgiwrap has content" spell_has_content

shows_help() {
  run_spell spells/.arcana/web-wizardry/uninstall-fcgiwrap --help
  true
}
run_test_case "uninstall-fcgiwrap shows help" shows_help

finish_tests
