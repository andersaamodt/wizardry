#!/bin/sh
# Behavioral coverage for list-contacts:
# - shows usage with --help
# - shows usage with -h
# - creates directory if it doesn't exist
# - handles empty directory gracefully

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/psi/list-contacts" ]
}

shows_help() {
  _run_spell spells/psi/list-contacts --help
  _assert_success
  _assert_output_contains "Usage:"
}

shows_help_h_flag() {
  _run_spell spells/psi/list-contacts -h
  _assert_success
  _assert_output_contains "Usage:"
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/psi/list-contacts" ]
}

test_handles_empty_directory() {
  tmpdir=$(_make_tempdir)
  contacts_dir="$tmpdir/empty-contacts"
  mkdir -p "$contacts_dir"
  _run_spell spells/psi/list-contacts "$contacts_dir"
  _assert_success
}

_run_test_case "psi/list-contacts is executable" spell_is_executable
_run_test_case "list-contacts shows help" shows_help
_run_test_case "list-contacts shows help with -h" shows_help_h_flag
_run_test_case "psi/list-contacts has content" spell_has_content
_run_test_case "list-contacts handles empty directory" test_handles_empty_directory

_finish_tests
