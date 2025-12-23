#!/bin/sh
# Test word-of-binding with both imps and spells

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test: word-of-binding correctly handles imps (with underscore prefix)
test_handles_imps_with_underscore() {
  skip-if-compiled || return $?
  # The 'say' imp defines _say() function
  _run_spell "spells/.imps/sys/word-of-binding" say "test message"
  _assert_success || return 1
  _assert_output_contains "test message" || return 1
}

# Test: word-of-binding correctly handles spells (without underscore prefix)
test_handles_spells_without_underscore() {
  skip-if-compiled || return $?
  # The 'forall' spell defines forall() function (not _forall())
  _run_spell "spells/.imps/sys/word-of-binding" forall --help
  _assert_success || return 1
  _assert_output_contains "Usage:" || return 1
}

# Test: word-of-binding can handle imp with hyphenated name
test_handles_hyphenated_imp() {
  skip-if-compiled || return $?
  # The 'usage-error' imp defines _usage_error() function
  _run_spell "spells/.imps/sys/word-of-binding" usage-error "test-spell" "test error"
  _assert_status 2 || return 1
  _assert_error_contains "test-spell: test error" || return 1
}

# Test: word-of-binding can handle spell with hyphenated name
test_handles_hyphenated_spell() {
  skip-if-compiled || return $?
  # The 'read-magic' spell defines read_magic() function (not _read_magic())
  # Call with --help to avoid file requirements
  _run_spell "spells/.imps/sys/word-of-binding" read-magic --help
  _assert_success || return 1
  _assert_output_contains "Usage:" || return 1
}

# Test: word-of-binding distinguishes between imps and spells
test_distinguishes_imp_vs_spell() {
  skip-if-compiled || return $?
  
  # Test an imp: say defines _say()
  _run_spell "spells/.imps/sys/word-of-binding" say "imp test"
  _assert_success || return 1
  _assert_output_contains "imp test" || return 1
  
  # Test a spell: forall defines forall() (not _forall())
  _run_spell "spells/.imps/sys/word-of-binding" forall --help
  _assert_success || return 1
  _assert_output_contains "Usage:" || return 1
}

_run_test_case "word-of-binding handles imps with underscore prefix" test_handles_imps_with_underscore
_run_test_case "word-of-binding handles spells without underscore prefix" test_handles_spells_without_underscore
_run_test_case "word-of-binding handles hyphenated imp names" test_handles_hyphenated_imp
_run_test_case "word-of-binding handles hyphenated spell names" test_handles_hyphenated_spell
_run_test_case "word-of-binding distinguishes imps vs spells" test_distinguishes_imp_vs_spell

_finish_tests
