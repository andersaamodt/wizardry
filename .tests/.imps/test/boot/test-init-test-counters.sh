#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_initializes_counters() {
  # Source the imp to test it initializes counters
  . "$test_root/spells/.imps/test/boot/init-test-counters"
  
  # Check that counters are initialized
  [ "${_pass_count:-unset}" != "unset" ] || return 1
  [ "${_fail_count:-unset}" != "unset" ] || return 1
  [ "${_skip_count:-unset}" != "unset" ] || return 1
}

test_counters_start_at_zero() {
  # Source the imp
  . "$test_root/spells/.imps/test/boot/init-test-counters"
  
  # Verify counters start at zero
  [ "$_pass_count" = "0" ] || return 1
  [ "$_fail_count" = "0" ] || return 1
  [ "$_skip_count" = "0" ] || return 1
}

_run_test_case "initializes test counters" test_initializes_counters
_run_test_case "counters start at zero" test_counters_start_at_zero
_finish_tests
