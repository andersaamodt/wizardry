#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell spells/system/demo-magic --help
  assert_success || return 1
  assert_output_contains "Usage: demo-magic" || return 1
}

test_level_0() {
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/system/demo-magic 0
  assert_success || return 1
  assert_output_contains "Level 0: POSIX & Platform Foundation" || return 1
  assert_output_contains "The wizard examines the foundation" || return 1
  assert_output_contains "The wizard casts detect-posix" || return 1
  assert_output_contains "Wizardry stands ready" || return 1
}

test_level_1() {
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/system/demo-magic 1
  assert_success || return 1
  assert_output_contains "Level 1: Banish & Validation Infrastructure" || return 1
  assert_output_contains "The wizard casts validate-spells" || return 1
  assert_output_contains "✓ Found spell: banish" || return 1
  assert_output_contains "Core imps summoned" || return 1
}

test_level_3() {
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/system/demo-magic 3
  assert_success || return 1
  assert_output_contains "Level 3: Glossary System" || return 1
  # Level 3 is now glossary system, not menu system
  assert_output_contains "The wizard conjures the glossary system" || return 1
}

test_level_7() {
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/system/demo-magic 7
  assert_success || return 1
  assert_output_contains "Level 7: Arcane File Operations" || return 1
  assert_output_contains "The wizard casts read-magic" || return 1
}

test_level_8() {
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/system/demo-magic 8
  assert_success || return 1
  assert_output_contains "Level 8: Basic Cantrips" || return 1
  assert_output_contains "The wizard casts ask-yn" || return 1
  assert_output_contains "Is this a demonstration?" || return 1
}

test_default_level() {
  # Test that demo-magic works with no level argument (defaults to 0 and 1)
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/system/demo-magic
  assert_success || return 1
  assert_output_contains "Level 0: POSIX & Platform Foundation" || return 1
  assert_output_contains "Level 1: Banish & Validation Infrastructure" || return 1
}

run_test_case "demo-magic shows help" test_help
run_test_case "demo-magic level 0 demonstrates actual spells" test_level_0
run_test_case "demo-magic level 1 runs validate-spells" test_level_1
run_test_case "demo-magic level 3 runs fathom-terminal" test_level_3
run_test_case "demo-magic level 7 runs read-magic" test_level_7
run_test_case "demo-magic level 8 runs ask-yn" test_level_8
run_test_case "demo-magic works with default level" test_default_level

finish_tests
