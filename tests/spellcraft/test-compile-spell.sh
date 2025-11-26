#!/bin/sh
# Tests for the 'compile-spell' spell

. "${0%/*}/../test-common.sh"

test_compile_spell_help() {
  run_spell spells/spellcraft/compile-spell --help
  assert_success
  assert_output_contains "Usage: compile-spell"
}

test_compile_spell_requires_args() {
  run_spell spells/spellcraft/compile-spell
  assert_failure
  assert_error_contains "spell name required"
}

test_compile_spell_unknown_spell() {
  run_spell spells/spellcraft/compile-spell nonexistent_spell_xyz
  assert_failure
  assert_error_contains "not found"
}

run_test_case "compile-spell shows help" test_compile_spell_help
run_test_case "compile-spell requires arguments" test_compile_spell_requires_args
run_test_case "compile-spell fails for unknown spell" test_compile_spell_unknown_spell

finish_tests
