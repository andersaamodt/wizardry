#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell spells/system/demonstrate-wizardry --help
  _assert_success || return 1
  _assert_output_contains "Usage: demonstrate-wizardry" || return 1
}

test_works_with_no_arguments() {
  # Test that demonstrate-wizardry works when called without arguments
  # This is different from the full output test as it just checks success
  WIZARDRY_DEMO_NO_BWRAP=1 _run_spell spells/system/demonstrate-wizardry
  _assert_success || return 1
  _assert_output_contains "Wizardry stands ready" || return 1
}

demonstration_output_matches() {
  WIZARDRY_DEMO_NO_BWRAP=1 _run_spell spells/system/demonstrate-wizardry
  _assert_success || return 1

  expected=$(cat <<'OUT'
A circle of chalk flares into view.
The wizardry demonstration begins.
Validating core spells:
menu: ready
spellbook: ready
cast: ready
memorize: ready
look: ready
ask-yn: ready
wizard-cast: ready
test-magic: ready
The circle closes. Wizardry stands ready.
OUT
)

  if [ "${OUTPUT-}" != "$expected" ]; then
    TEST_FAILURE_REASON="output did not match expected demonstration transcript"
    return 1
  fi
}

_run_test_case "demonstrate-wizardry shows help" test_help
_run_test_case "demonstrate-wizardry works with no arguments" test_works_with_no_arguments
_run_test_case "demonstrate-wizardry output matches expected transcript" demonstration_output_matches


# Test via source-then-invoke pattern  
