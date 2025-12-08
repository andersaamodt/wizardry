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
  skip-if-compiled || return $?
  _run_spell spells/spellcraft/compile-spell --help
  _assert_success
  _assert_output_contains "Usage: compile-spell"
}

test_compile_spell_help_h_flag() {
  skip-if-compiled || return $?
  _run_spell spells/spellcraft/compile-spell -h
  _assert_success
  _assert_output_contains "Usage: compile-spell"
}

test_compile_spell_requires_args() {
  _run_spell spells/spellcraft/compile-spell
  _assert_failure
  _assert_error_contains "spell name required"
}

test_compile_spell_unknown_spell() {
  _run_spell spells/spellcraft/compile-spell nonexistent_spell_xyz
  _assert_failure
  _assert_error_contains "not found"
}

_run_test_case "compile-spell shows help" test_compile_spell_help
_run_test_case "compile-spell shows help with -h" test_compile_spell_help_h_flag
_run_test_case "compile-spell requires arguments" test_compile_spell_requires_args
_run_test_case "compile-spell fails for unknown spell" test_compile_spell_unknown_spell

_finish_tests
