#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_spell spells/system/pocket-dimension --help
  assert_success
  assert_output_contains "Usage: pocket-dimension"
}

check_reports_availability() {
  platform=$(uname -s 2>/dev/null || printf 'unknown')
  if [ "$platform" = "Linux" ] && ! command -v bwrap >/dev/null 2>&1; then
    run_spell spells/system/pocket-dimension --check
    assert_failure
    assert_error_contains "bwrap not found"
    return 0
  fi

  run_spell spells/system/pocket-dimension --check
  assert_success
}

clears_environment() {
  FOO_IN_POCKET=present run_spell spells/system/pocket-dimension -- sh -c 'test -z "${FOO_IN_POCKET-}"'
  assert_success
}

sets_pocket_flag() {
  run_spell spells/system/pocket-dimension -- sh -c 'test "${WIZARDRY_TEST_IN_POCKET-}" = "1"'
  assert_success
}

run_test_case "pocket-dimension shows help" shows_help
run_test_case "pocket-dimension check reports availability" check_reports_availability
run_test_case "pocket-dimension clears environment" clears_environment
run_test_case "pocket-dimension sets pocket flag" sets_pocket_flag

finish_tests
