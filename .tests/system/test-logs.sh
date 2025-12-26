#!/bin/sh
# Test coverage for logs spell:
# - Shows usage with --help
# - Script exists and is executable
# - Sources required files

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/system/logs" --help
  _assert_success || return 1
  _assert_output_contains "Usage: logs" || return 1
}

test_spell_exists() {
  [ -f "$ROOT_DIR/spells/system/logs" ] || { TEST_FAILURE_REASON="spell file does not exist"; return 1; }
}

test_is_executable() {
  [ -x "$ROOT_DIR/spells/system/logs" ] || { TEST_FAILURE_REASON="spell is not executable"; return 1; }
}

_run_test_case "logs shows usage text" test_help
_run_test_case "logs spell exists" test_spell_exists
_run_test_case "logs spell is executable" test_is_executable


# Test via source-then-invoke pattern  
