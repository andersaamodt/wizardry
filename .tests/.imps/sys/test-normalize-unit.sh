#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

test_normalize_adds_service_suffix() {
  run_spell "spells/.imps/sys/normalize-unit" "myunit"
  assert_success && assert_output_contains "myunit.service"
}

test_normalize_preserves_existing_suffix() {
  run_spell "spells/.imps/sys/normalize-unit" "myunit.service"
  assert_success && assert_output_contains "myunit.service"
}

test_normalize_handles_socket_units() {
  run_spell "spells/.imps/sys/normalize-unit" "myunit.socket"
  assert_success && assert_output_contains "myunit.socket"
}

run_test_case "normalize-unit adds .service suffix" test_normalize_adds_service_suffix
run_test_case "normalize-unit preserves existing suffix" test_normalize_preserves_existing_suffix
run_test_case "normalize-unit handles other unit types" test_normalize_handles_socket_units
finish_tests
