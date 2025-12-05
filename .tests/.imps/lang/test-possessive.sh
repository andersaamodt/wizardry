#!/bin/sh
# Tests for the possessive imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_adds_s_when_needed() {
  _run_spell spells/.imps/lang/possessive wizard
  _assert_success || return 1
  _assert_output_contains "wizard's" || return 1
}

test_appends_apostrophe_for_s_ending() {
  _run_spell spells/.imps/lang/possessive glass
  _assert_success || return 1
  _assert_output_contains "glass'" || return 1
}

test_keeps_existing_apostrophe() {
  _run_spell spells/.imps/lang/possessive "James'"
  _assert_success || return 1
  _assert_output_contains "James'" || return 1
}

_run_test_case "adds 's for standard nouns" test_adds_s_when_needed
_run_test_case "adds apostrophe for nouns ending with s" test_appends_apostrophe_for_s_ending
_run_test_case "leaves existing apostrophe intact" test_keeps_existing_apostrophe
_finish_tests
