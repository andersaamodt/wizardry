#!/bin/sh
# Behavioral coverage for ssh-barrier:
# - shows usage with --help
# - shows usage with -h
# - spell file exists and has content

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_exists() {
  [ -f "$ROOT_DIR/spells/wards/ssh-barrier" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/wards/ssh-barrier" ]
}

run_test_case "wards/ssh-barrier exists" spell_exists
run_test_case "wards/ssh-barrier has content" spell_has_content

shows_help() {
  run_spell spells/wards/ssh-barrier --help
  assert_success && assert_output_contains "Usage: ssh-barrier"
}

shows_help_h_flag() {
  run_spell spells/wards/ssh-barrier -h
  assert_success && assert_output_contains "Usage: ssh-barrier"
}

run_test_case "ssh-barrier shows help" shows_help
run_test_case "ssh-barrier shows help with -h" shows_help_h_flag
finish_tests
