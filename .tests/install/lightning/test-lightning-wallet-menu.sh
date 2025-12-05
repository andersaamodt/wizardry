#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/lightning/lightning-wallet-menu" ]
}
_run_test_case "install/lightning/lightning-wallet-menu is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/lightning/lightning-wallet-menu" ]
}
_run_test_case "install/lightning/lightning-wallet-menu has content" spell_has_content

shows_usage_help() {
  _run_spell spells/install/lightning/lightning-wallet-menu --help
  _assert_success || return 1
  _assert_output_contains "Usage: lightning-wallet-menu"
}
_run_test_case "lightning-wallet-menu shows usage help" shows_usage_help

contains_wallet_actions() {
  _assert_file_contains "$ROOT_DIR/spells/install/lightning/lightning-wallet-menu" "lightning-cli listfunds"
  _assert_file_contains "$ROOT_DIR/spells/install/lightning/lightning-wallet-menu" "lightning-cli newaddr"
}
_run_test_case "lightning-wallet-menu lists wallet actions" contains_wallet_actions

_finish_tests
