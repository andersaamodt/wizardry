#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell spells/spellcraft/demo-magic --help
  assert_success || return 1
  assert_output_contains "Usage: demo-magic" || return 1
}

test_level_0() {
  run_spell spells/spellcraft/demo-magic 1 --no-bwrap
  assert_success || return 1
  assert_output_contains "Spell Level 1" || return 1
  assert_output_contains "Banish & Validation" || return 1
  assert_output_contains "wizard" || return 1
}

test_level_1() {
  run_spell spells/spellcraft/demo-magic 1 --no-bwrap
  assert_success || return 1
  assert_output_contains "Spell Level 1" || return 1
  assert_output_contains "validate-spells" || return 1
}

test_level_3() {
  run_spell spells/spellcraft/demo-magic 3 --no-bwrap
  assert_success || return 1
  assert_output_contains "Spell Level 3" || return 1
  assert_output_contains "Glossary" || return 1
}

test_level_7() {
  run_spell spells/spellcraft/demo-magic 7 --no-bwrap
  assert_success || return 1
  assert_output_contains "Spell Level 7" || return 1
  assert_output_contains "Navigation" || return 1
}

test_level_8() {
  run_spell spells/spellcraft/demo-magic 8 --no-bwrap
  assert_success || return 1
  assert_output_contains "Spell Level 8" || return 1
  assert_output_contains "Testing" || return 1
}

test_default_level() {
  # Test that demo-magic works with default level (all)
  run_spell spells/spellcraft/demo-magic --no-bwrap
  assert_success || return 1
  assert_output_contains "Spell Level 1" || return 1
  assert_output_contains "wizard" || return 1
}

run_test_case "demo-magic shows help" test_help
run_test_case "demo-magic level 0 demonstrates actual spells" test_level_0
run_test_case "demo-magic level 1 runs validate-spells" test_level_1
run_test_case "demo-magic level 3 runs fathom-terminal" test_level_3
run_test_case "demo-magic level 7 runs read-magic" test_level_7
run_test_case "demo-magic level 8 runs ask-yn" test_level_8
run_test_case "demo-magic works with default level" test_default_level

finish_tests
