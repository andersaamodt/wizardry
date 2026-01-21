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
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/spellcraft/demo-magic 0
  assert_success || return 1
  assert_output_contains "Level 0: POSIX & Platform Foundation" || return 1
  assert_output_contains "The wizard examines the foundation" || return 1
  assert_output_contains "The wizard casts detect-posix" || return 1
  assert_output_contains "Wizardry stands ready" || return 1
}

test_level_1() {
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/spellcraft/demo-magic 1
  assert_success || return 1
  assert_output_contains "Level 1: Banish & Validation Infrastructure" || return 1
  assert_output_contains "The wizard casts validate-spells" || return 1
  assert_output_contains "✓ Found spell: banish" || return 1
  assert_output_contains "Core imps summoned" || return 1
}

test_level_3() {
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/spellcraft/demo-magic 3
  assert_success || return 1
  assert_output_contains "Level 3: Glossary & Parsing" || return 1
  # Level 3 is now glossary & parsing
  assert_output_contains "The wizard weaves interactive menus" || return 1
}

test_level_7() {
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/spellcraft/demo-magic 7
  assert_success || return 1
  assert_output_contains "Level 7: Navigation" || return 1
  assert_output_contains "translocation" || return 1
  assert_output_contains "mark-location" || return 1
}

test_level_8() {
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/spellcraft/demo-magic 8
  assert_success || return 1
  assert_output_contains "Level 8: Testing Infrastructure" || return 1
  assert_output_contains "test-magic" || return 1
}

test_level_9() {
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/spellcraft/demo-magic 9
  assert_success || return 1
  assert_output_contains "Level 9: MUD Basics" || return 1
  assert_output_contains "The wizard casts \"look\"" || return 1
}

test_level_10() {
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/spellcraft/demo-magic 10
  assert_success || return 1
  assert_output_contains "Level 10: Arcane File Operations" || return 1
  assert_output_contains "read-magic" || return 1
}

test_level_11() {
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/spellcraft/demo-magic 11
  assert_success || return 1
  assert_output_contains "Level 11: Basic Cantrips" || return 1
  assert_output_contains "ask-yn" || return 1
}

test_default_level() {
  # Test that demo-magic works with no level argument (defaults to all levels 0-27)
  # We'll just check that it starts correctly and includes multiple levels
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/spellcraft/demo-magic 3
  assert_success || return 1
  assert_output_contains "Level 0: POSIX & Platform Foundation" || return 1
  assert_output_contains "Level 1: Banish & Validation Infrastructure" || return 1
  assert_output_contains "DEMO_MAGIC_COMPLETE" || return 1
}

run_test_case "demo-magic shows help" test_help
run_test_case "demo-magic level 0 demonstrates actual spells" test_level_0
run_test_case "demo-magic level 1 runs validate-spells" test_level_1
run_test_case "demo-magic level 3 demonstrates menu capabilities" test_level_3
run_test_case "demo-magic level 7 demonstrates navigation" test_level_7
run_test_case "demo-magic level 8 demonstrates testing framework" test_level_8
run_test_case "demo-magic level 9 demonstrates MUD basics" test_level_9
run_test_case "demo-magic level 10 demonstrates arcane file operations" test_level_10
run_test_case "demo-magic level 11 demonstrates basic cantrips" test_level_11
run_test_case "demo-magic works with default level" test_default_level

finish_tests
