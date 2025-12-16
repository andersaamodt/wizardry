#!/bin/sh
set -eu

# Locate test root to source helpers
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/lightning/install-lightning" ]
}
_run_test_case "install/lightning/install-lightning is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/lightning/install-lightning" ]
}
_run_test_case "install/lightning/install-lightning has content" spell_has_content

shows_usage_help() {
  _run_spell spells/.arcana/lightning/install-lightning --help
  _assert_success || return 1
  _assert_error_contains "Usage: install-lightning"
}
_run_test_case "install-lightning shows usage help" shows_usage_help

_finish_tests
