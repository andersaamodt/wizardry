#!/bin/sh
# Tests for the possessive imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_adds_s_when_needed() {
  run_spell spells/.imps/lang/possessive wizard
  assert_success || return 1
  assert_output_contains "wizard's" || return 1
}

test_appends_apostrophe_for_s_ending() {
  run_spell spells/.imps/lang/possessive glass
  assert_success || return 1
  assert_output_contains "glass'" || return 1
}

test_keeps_existing_apostrophe() {
  run_spell spells/.imps/lang/possessive "James'"
  assert_success || return 1
  assert_output_contains "James'" || return 1
}

run_test_case "adds 's for standard nouns" test_adds_s_when_needed
run_test_case "adds apostrophe for nouns ending with s" test_appends_apostrophe_for_s_ending
run_test_case "leaves existing apostrophe intact" test_keeps_existing_apostrophe
finish_tests
