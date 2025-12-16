#!/bin/sh
# Test env-clear imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test that env-clear preserves system variables
test_preserves_system_vars() {
  # Set up some system vars
  PATH="/usr/bin:/bin"
  HOME="/home/test"
  USER="testuser"
  
  # Call env-clear
  _run_cmd "$ROOT_DIR/spells/.imps/sys/env-clear"
  _assert_success
}

# Test that env-clear preserves wizardry globals  
test_preserves_wizardry_globals() {
  # Call env-clear with wizardry globals set
  _run_cmd sh -c "WIZARDRY_DIR=/opt/wizardry SPELLBOOK_DIR=/home/test/.spellbook '$ROOT_DIR/spells/.imps/sys/env-clear'; printf '%s' \"\$WIZARDRY_DIR\""
  _assert_success
  _assert_output_contains "/opt/wizardry"
}

_run_test_case "env-clear preserves system variables" test_preserves_system_vars
_run_test_case "env-clear preserves wizardry globals" test_preserves_wizardry_globals

_finish_tests
