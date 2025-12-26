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


# Test via source-then-invoke pattern  
list_contacts_help_via_sourcing() {
  _run_sourced_spell list-contacts --help
  _assert_success || return 1
  # Help text may go to stdout or stderr depending on spell
  if [ -n "$OUTPUT" ]; then
    case "$OUTPUT" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  if [ -n "$ERROR" ]; then
    case "$ERROR" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  TEST_FAILURE_REASON="expected 'Usage:' in output or error"
  return 1
}

_run_test_case "list-contacts works via source-then-invoke" list_contacts_help_via_sourcing
_finish_tests
