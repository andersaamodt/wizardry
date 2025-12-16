#!/bin/sh
# Tests for the 'env-clear' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_env_clear_succeeds() {
  # env-clear must exit with 0 when sourced
  OUTPUT=$(sh -c "cd '$test_root' && set -eu; . spells/.imps/sys/env-clear && echo 'success'" 2>&1)
  STATUS=$?
  [ "$STATUS" -eq 0 ] || { TEST_FAILURE_REASON="env-clear failed with status $STATUS"; return 1; }
  case "$OUTPUT" in
    *success*) return 0 ;;
    *) TEST_FAILURE_REASON="env-clear did not output success"; return 1 ;;
  esac
}

test_env_clear_preserves_path() {
  # env-clear must preserve PATH
  OUTPUT=$(sh -c "cd '$test_root' && set -eu; saved_path=\"\$PATH\"; . spells/.imps/sys/env-clear; [ -n \"\$PATH\" ] && [ \"\$PATH\" = \"\$saved_path\" ] && echo 'preserved'" 2>&1)
  STATUS=$?
  [ "$STATUS" -eq 0 ] || { TEST_FAILURE_REASON="PATH not preserved"; return 1; }
  case "$OUTPUT" in
    *preserved*) return 0 ;;
    *) TEST_FAILURE_REASON="PATH check failed"; return 1 ;;
  esac
}

test_env_clear_preserves_home() {
  # env-clear must preserve HOME
  OUTPUT=$(sh -c "cd '$test_root' && set -eu; saved_home=\"\$HOME\"; . spells/.imps/sys/env-clear; [ -n \"\$HOME\" ] && [ \"\$HOME\" = \"\$saved_home\" ] && echo 'preserved'" 2>&1)
  STATUS=$?
  [ "$STATUS" -eq 0 ] || { TEST_FAILURE_REASON="HOME not preserved"; return 1; }
  case "$OUTPUT" in
    *preserved*) return 0 ;;
    *) TEST_FAILURE_REASON="HOME check failed"; return 1 ;;
  esac
}

test_env_clear_clears_custom_vars() {
  # env-clear should clear non-essential exported variables
  OUTPUT=$(sh -c "cd '$test_root' && set -eu; export CUSTOM_TEST_VAR='test'; . spells/.imps/sys/env-clear; [ -z \"\${CUSTOM_TEST_VAR:-}\" ] && echo 'cleared'" 2>&1)
  STATUS=$?
  [ "$STATUS" -eq 0 ] || { TEST_FAILURE_REASON="custom var not cleared"; return 1; }
  case "$OUTPUT" in
    *cleared*) return 0 ;;
    *) TEST_FAILURE_REASON="custom var check failed"; return 1 ;;
  esac
}

test_env_clear_preserves_wizardry_globals() {
  # env-clear must preserve WIZARDRY_DIR if set
  OUTPUT=$(sh -c "cd '$test_root' && set -eu; export WIZARDRY_DIR='/test/dir'; . spells/.imps/sys/env-clear; [ \"\$WIZARDRY_DIR\" = '/test/dir' ] && echo 'preserved'" 2>&1)
  STATUS=$?
  [ "$STATUS" -eq 0 ] || { TEST_FAILURE_REASON="WIZARDRY_DIR not preserved"; return 1; }
  case "$OUTPUT" in
    *preserved*) return 0 ;;
    *) TEST_FAILURE_REASON="WIZARDRY_DIR check failed"; return 1 ;;
  esac
}

_run_test_case "env-clear exits successfully when sourced" test_env_clear_succeeds
_run_test_case "env-clear preserves PATH" test_env_clear_preserves_path
_run_test_case "env-clear preserves HOME" test_env_clear_preserves_home
_run_test_case "env-clear clears custom exported variables" test_env_clear_clears_custom_vars
_run_test_case "env-clear preserves WIZARDRY_DIR" test_env_clear_preserves_wizardry_globals

_finish_tests
