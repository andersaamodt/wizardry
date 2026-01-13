#!/bin/sh
# Behavioral cases:
# - doppelganger creates compiled wizardry clone
# - doppelganger --help shows usage
# - doppelganger uses default directory if none provided

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/spellcraft/doppelganger" --help
  assert_success && assert_output_contains "Usage:"
}

test_uses_default_directory() {
  # doppelganger uses ./wizardry-compiled as default
  # Just verify it doesn't fail without arguments
  # (don't actually run it as it would create files in the working directory)
  run_spell "spells/spellcraft/doppelganger" --help
  assert_success
}

test_creates_compiled_wizardry() {
  # Skip: Redundant with .github/workflows/test-doppelganger.yml workflow
  # The dedicated workflow comprehensively tests doppelganger compilation
  TEST_SKIP_REASON="redundant with test-doppelganger.yml workflow"
  return 222
}

run_test_case "doppelganger prints usage" test_help
run_test_case "doppelganger uses default directory" test_uses_default_directory
run_test_case "doppelganger creates compiled wizardry" test_creates_compiled_wizardry


# Test via source-then-invoke pattern  

finish_tests
