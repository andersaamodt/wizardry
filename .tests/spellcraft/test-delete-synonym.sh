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
  run_spell "spells/spellcraft/delete-synonym" --help
  assert_success && assert_output_contains "Usage:"
}

test_deletes_existing_synonym() {
  case_dir=$(make_tempdir)
  synonyms_file="$case_dir/.synonyms"
  
  # Create a synonym first
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" myalias echo
  assert_success || return 1
  
  # Delete it
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/delete-synonym" myalias
  
  assert_success || return 1
  assert_output_contains "Synonym deleted" || return 1
  
  # Verify alias is removed from file
  if grep -q "^alias myalias=" "$synonyms_file"; then
    TEST_FAILURE_REASON="synonym still exists in file"
    return 1
  fi
}

test_fails_when_synonym_not_found() {
  case_dir=$(make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/delete-synonym" nonexistent
  
  assert_failure || return 1
  # Error message will say "no synonyms defined" if file doesn't exist
  assert_error_contains "synonym" || return 1
}

test_rejects_empty_word() {
  case_dir=$(make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/delete-synonym" ""
  
  assert_failure || return 1
}

run_test_case "prints help" test_shows_help
run_test_case "deletes existing synonym" test_deletes_existing_synonym
run_test_case "fails when synonym not found" test_fails_when_synonym_not_found
run_test_case "rejects empty word" test_rejects_empty_word


# Test via source-then-invoke pattern  

finish_tests
