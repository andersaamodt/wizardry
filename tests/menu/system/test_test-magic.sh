#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/../../test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/../../test_common.sh"

runs_listing_from_menu() {
  run_cmd "$ROOT_DIR/spells/menu/system/test-magic" --list
  assert_success || return 1
  printf '%s\n' "$OUTPUT" | head -n 1 | grep 'arcane/' >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="expected test listing from system menu"; return 1;
  }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

run_test_case "system test-magic delegates to root runner" runs_listing_from_menu

finish_tests
