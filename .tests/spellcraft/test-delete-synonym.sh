#!/bin/sh
# Tests for delete-synonym spell
# - prints usage with --help
# - deletes existing synonym from alias file
# - fails when synonym doesn't exist

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_shows_help() {
  _run_spell "spells/spellcraft/delete-synonym" --help
  _assert_success && _assert_output_contains "Usage:"
}

test_deletes_existing_synonym() {
  case_dir=$(_make_tempdir)
  synonyms_file="$case_dir/.synonyms"
  
  # Create a synonym first
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" myalias echo
  _assert_success || return 1
  
  # Delete it
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/delete-synonym" myalias
  
  _assert_success || return 1
  _assert_output_contains "Synonym deleted" || return 1
  
  # Verify alias is removed from file
  if grep -q "^alias myalias=" "$synonyms_file"; then
    TEST_FAILURE_REASON="synonym still exists in file"
    return 1
  fi
}

test_fails_when_synonym_not_found() {
  case_dir=$(_make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/delete-synonym" nonexistent
  
  _assert_failure || return 1
  # Error message will say "no synonyms defined" if file doesn't exist
  _assert_error_contains "synonym" || return 1
}

test_rejects_empty_word() {
  case_dir=$(_make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/delete-synonym" ""
  
  _assert_failure || return 1
}

_run_test_case "prints help" test_shows_help
_run_test_case "deletes existing synonym" test_deletes_existing_synonym
_run_test_case "fails when synonym not found" test_fails_when_synonym_not_found
_run_test_case "rejects empty word" test_rejects_empty_word


# Test via source-then-invoke pattern  
delete_synonym_help_via_sourcing() {
  _run_sourced_spell delete-synonym --help
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

_run_test_case "delete-synonym works via source-then-invoke" delete_synonym_help_via_sourcing
_finish_tests
