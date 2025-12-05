#!/bin/sh
# Test coverage for merge-yaml-text spell:
# - Shows usage with --help
# - Is POSIX compliant

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

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
