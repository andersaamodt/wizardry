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
  assert_output_contains "Wizardry stands ready" || return 1
}

test_level_1() {
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/system/demo-magic 1
  assert_success || return 1
  assert_output_contains "Level 1: Wizardry Installation" || return 1
  assert_output_contains "The wizard casts banish ... ready" || return 1
  assert_output_contains "The wizard casts validate-spells ... ready" || return 1
  assert_output_contains "Wizardry stands ready" || return 1
}

test_level_3() {
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/system/demo-magic 3
  assert_success || return 1
  assert_output_contains "Level 3: Menu System" || return 1
  assert_output_contains "The wizard weaves interactive menus" || return 1
  assert_output_contains "The wizard casts menu ... ready" || return 1
}

test_level_7() {
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/system/demo-magic 7
  assert_success || return 1
  assert_output_contains "Level 7: Arcane File Operations" || return 1
  assert_output_contains "The wizard casts copy ... ready" || return 1
  assert_output_contains "The wizard casts read-magic ... ready" || return 1
}

test_default_level() {
  # Test that demo-magic works with no level argument (defaults to 1)
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/system/demo-magic
  assert_success || return 1
  assert_output_contains "Level 0: POSIX & Platform Foundation" || return 1
  assert_output_contains "Level 1: Wizardry Installation" || return 1
}

run_test_case "demo-magic shows help" test_help
run_test_case "demo-magic level 0 works" test_level_0
run_test_case "demo-magic level 1 works" test_level_1
run_test_case "demo-magic level 3 works" test_level_3
run_test_case "demo-magic level 7 works" test_level_7
run_test_case "demo-magic works with default level" test_default_level

finish_tests
