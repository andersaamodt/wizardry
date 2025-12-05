#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/lightning/lightning-status" ]
}
run_test_case "install/lightning/lightning-status is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/lightning/lightning-status" ]
}
run_test_case "install/lightning/lightning-status has content" spell_has_content

shows_usage_help() {
  run_spell spells/install/lightning/lightning-status --help
  assert_success || return 1
  assert_error_contains "Usage: lightning-status"
}
run_test_case "lightning-status shows usage help" shows_usage_help

checks_lightning_cli() {
  assert_file_contains "$ROOT_DIR/spells/install/lightning/lightning-status" "lightning-cli"
}
run_test_case "lightning-status references lightning-cli" checks_lightning_cli

finish_tests
