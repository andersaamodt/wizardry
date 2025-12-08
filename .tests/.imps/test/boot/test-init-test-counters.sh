#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

test_initializes_counters() {
  # Source the imp to test it initializes counters
  . "$ROOT_DIR/spells/.imps/test/boot/init-test-counters"
  
  # Check that counters are initialized
  [ "${_pass_count:-unset}" != "unset" ] || return 1
  [ "${_fail_count:-unset}" != "unset" ] || return 1
  [ "${_skip_count:-unset}" != "unset" ] || return 1
}

test_counters_start_at_zero() {
  # Source the imp
  . "$ROOT_DIR/spells/.imps/test/boot/init-test-counters"
  
  # Verify counters start at zero
  [ "$_pass_count" = "0" ] || return 1
  [ "$_fail_count" = "0" ] || return 1
  [ "$_skip_count" = "0" ] || return 1
}

run_test_case "initializes test counters" test_initializes_counters
run_test_case "counters start at zero" test_counters_start_at_zero
finish_tests
