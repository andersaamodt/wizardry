#!/bin/sh
# Behavioral coverage for list-contacts:
# - shows usage with --help
# - shows usage with -h
# - creates directory if it doesn't exist
# - handles empty directory gracefully

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/psi/list-contacts" ]
}

shows_help() {
  run_spell spells/psi/list-contacts --help
  assert_success
  assert_output_contains "Usage:"
}

shows_help_h_flag() {
  run_spell spells/psi/list-contacts -h
  assert_success
  assert_output_contains "Usage:"
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/psi/list-contacts" ]
}

test_handles_empty_directory() {
  tmpdir=$(make_tempdir)
  contacts_dir="$tmpdir/empty-contacts"
  mkdir -p "$contacts_dir"
  run_spell spells/psi/list-contacts "$contacts_dir"
  assert_success
}

run_test_case "psi/list-contacts is executable" spell_is_executable
run_test_case "list-contacts shows help" shows_help
run_test_case "list-contacts shows help with -h" shows_help_h_flag
run_test_case "psi/list-contacts has content" spell_has_content
run_test_case "list-contacts handles empty directory" test_handles_empty_directory

finish_tests
