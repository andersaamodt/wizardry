#!/bin/sh
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

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
