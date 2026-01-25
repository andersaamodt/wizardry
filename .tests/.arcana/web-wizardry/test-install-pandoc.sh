#!/bin/sh
set -eu

# Locate test helpers
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/web-wizardry/install-pandoc" ]
}

run_test_case "install-pandoc is executable" spell_is_executable

renders_usage_information() {
  skip-if-compiled || return $?
  run_cmd "$ROOT_DIR/spells/.arcana/web-wizardry/install-pandoc" --help

  assert_success || return 1
  assert_error_contains "Usage: install-pandoc" || return 1
  assert_error_contains "Installs pandoc" || return 1
}

run_test_case "install-pandoc prints usage with --help" renders_usage_information

finish_tests
