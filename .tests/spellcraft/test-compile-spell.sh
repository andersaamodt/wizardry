#!/bin/sh
# Behavioral coverage for compile-spell:
# - shows usage with --help
# - shows usage with -h
# - requires spell name argument
# - fails for unknown spell

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_compile_spell_help() {
  _run_spell spells/spellcraft/compile-spell --help
  _assert_success
  _assert_output_contains "Usage: compile-spell"
}

test_compile_spell_help_h_flag() {
  _run_spell spells/spellcraft/compile-spell -h
  _assert_success
  _assert_output_contains "Usage: compile-spell"
}

test_compile_spell_requires_args() {
  skip-if-compiled || return $?
  _run_spell spells/spellcraft/compile-spell
  _assert_failure
  _assert_error_contains "Usage:"
}

test_compile_spell_unknown_spell() {
  skip-if-compiled || return $?
  _run_spell spells/spellcraft/compile-spell nonexistent_spell_xyz
  _assert_failure
  _assert_error_contains "not found"
}

_run_test_case "compile-spell shows help" test_compile_spell_help
_run_test_case "compile-spell shows help with -h" test_compile_spell_help_h_flag
_run_test_case "compile-spell requires arguments" test_compile_spell_requires_args
_run_test_case "compile-spell fails for unknown spell" test_compile_spell_unknown_spell


# Test via source-then-invoke pattern  
compile_spell_help_via_sourcing() {
  _run_sourced_spell compile-spell --help
  _assert_success || return 1
  # Help text may go to stdout or stderr depending on spell
  if [ -n "$OUTPUT" ]; then
    case "$OUTPUT" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  if [ -n "$ERROR" ]; then
    case "$ERROR" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  TEST_FAILURE_REASON="expected 'Usage:' in output or error"
  return 1
}

_run_test_case "compile-spell works via source-then-invoke" compile_spell_help_via_sourcing
_finish_tests
