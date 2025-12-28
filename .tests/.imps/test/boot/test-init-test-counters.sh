#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_initializes_counters() {
  # Run the imp in a subshell to test initialization without affecting our counters
  output=$(
    . "$test_root/spells/.imps/test/boot/init-test-counters"
    # Check that counters are initialized
    [ "${_pass_count:-unset}" != "unset" ] || exit 1
    [ "${_fail_count:-unset}" != "unset" ] || exit 1
    [ "${_skip_count:-unset}" != "unset" ] || exit 1
    [ "${_test_index:-unset}" != "unset" ] || exit 1
    echo "ok"
  )
  [ "$output" = "ok" ] || return 1
}

test_counters_start_at_zero() {
  # Run the imp in a subshell to test values without affecting our counters
  output=$(
    . "$test_root/spells/.imps/test/boot/init-test-counters"
    # Verify counters start at zero
    [ "$_pass_count" = "0" ] || exit 1
    [ "$_fail_count" = "0" ] || exit 1
    [ "$_skip_count" = "0" ] || exit 1
    [ "$_test_index" = "0" ] || exit 1
    echo "ok"
  )
  [ "$output" = "ok" ] || return 1
}

run_test_case "initializes test counters" test_initializes_counters
run_test_case "counters start at zero" test_counters_start_at_zero
finish_tests
