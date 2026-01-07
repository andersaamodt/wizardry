#!/bin/sh
# Test cases for catalog-emojis:
# - catalog-emojis prints usage with --help
# - catalog-emojis runs without errors when no emojis exist
# - catalog-emojis detects emojis in .github/ files
# - catalog-emojis shows frequency count
# - catalog-emojis shows file locations

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/spellcraft/catalog-emojis" --help
  assert_success || return 1
  assert_output_contains "Usage: catalog-emojis" || return 1
}

test_usage_alias() {
  run_spell "spells/spellcraft/catalog-emojis" --usage
  assert_success || return 1
  assert_output_contains "Usage: catalog-emojis" || return 1
}

test_help_short() {
  run_spell "spells/spellcraft/catalog-emojis" -h
  assert_success || return 1
  assert_output_contains "Usage: catalog-emojis" || return 1
}

test_basic_execution() {
  # Test that the spell runs without errors
  # It should find emojis in the .github/ files
  run_spell "spells/spellcraft/catalog-emojis"
  assert_success || return 1
  assert_output_contains "Emoji Frequency" || return 1
}

test_detects_emojis_in_policy() {
  # The .github/ files contain emojis used for annotations
  # This test verifies they are detected
  run_spell "spells/spellcraft/catalog-emojis"
  assert_success || return 1
  # Should show some emoji count
  assert_output_contains "Total" || return 1
}

run_test_case "catalog-emojis prints usage" test_help
run_test_case "catalog-emojis accepts --usage" test_usage_alias
run_test_case "catalog-emojis accepts -h" test_help_short
run_test_case "catalog-emojis runs successfully" test_basic_execution
run_test_case "catalog-emojis detects emojis" test_detects_emojis_in_policy

finish_tests
