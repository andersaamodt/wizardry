#!/bin/sh
# Test coverage for new-player spell:
# - Shows usage with --help
# - Is POSIX compliant

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_help() {
  run_spell "spells/menu/mud-admin/new-player" --help
  assert_success || return 1
  assert_output_contains "Usage: new-player" || return 1
}

test_help_h_flag() {
  run_spell "spells/menu/mud-admin/new-player" -h
  assert_success || return 1
  assert_output_contains "Usage: new-player" || return 1
}

test_has_strict_mode() {
  # Verify the spell uses strict mode
  grep -q "set -eu" "$ROOT_DIR/spells/menu/mud-admin/new-player" || {
    TEST_FAILURE_REASON="spell does not use strict mode"
    return 1
  }
}

run_test_case "new-player shows usage text" test_help
run_test_case "new-player shows usage with -h" test_help_h_flag
run_test_case "new-player uses strict mode" test_has_strict_mode

finish_tests
