#!/bin/sh
# Test coverage for merge-yaml-text spell:
# - Shows usage with --help
# - Is POSIX compliant

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/spellcraft/merge-yaml-text" --help
  assert_success || return 1
  assert_output_contains "Usage: merge-yaml-text" || return 1
}

test_help_h_flag() {
  run_spell "spells/spellcraft/merge-yaml-text" -h
  assert_success || return 1
  assert_output_contains "Usage: merge-yaml-text" || return 1
}

test_has_strict_mode() {
  # Verify the spell uses strict mode
  grep -q "set -eu" "$ROOT_DIR/spells/spellcraft/merge-yaml-text" || {
    TEST_FAILURE_REASON="spell does not use strict mode"
    return 1
  }
}

run_test_case "merge-yaml-text shows usage text" test_help
run_test_case "merge-yaml-text shows usage with -h" test_help_h_flag
run_test_case "merge-yaml-text uses strict mode" test_has_strict_mode

finish_tests
