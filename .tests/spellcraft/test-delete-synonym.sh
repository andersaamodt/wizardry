#!/bin/sh
# Tests for delete-synonym spell
# - prints usage with --help
# - deletes existing synonym from alias file
# - fails when synonym doesn't exist
# - matches synonym names literally
# - rejects extra operands before mutation

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
  if grep -q "^myalias=" "$synonyms_file"; then
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

test_deletes_literal_metacharacter_synonym_only() {
  case_dir=$(make_tempdir)
  synonyms_file="$case_dir/.synonyms"

  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" "my.alias" echo
  assert_success || return 1

  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" "myXalias" printf
  assert_success || return 1

  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/delete-synonym" "my.alias"

  assert_success || return 1
  if grep -F -q -e 'my.alias=' "$synonyms_file"; then
    TEST_FAILURE_REASON="literal metacharacter synonym still exists"
    return 1
  fi
  if ! grep -F -q -e 'myXalias=printf' "$synonyms_file"; then
    TEST_FAILURE_REASON="regex metacharacter delete removed the wrong synonym"
    return 1
  fi
}

test_rejects_extra_operands_before_delete() {
  case_dir=$(make_tempdir)
  synonyms_file="$case_dir/.synonyms"

  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" myalias echo
  assert_success || return 1

  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/delete-synonym" myalias extra

  assert_failure || return 1
  assert_error_contains "too many arguments" || return 1
  if ! grep -F -q -e 'myalias=echo' "$synonyms_file"; then
    TEST_FAILURE_REASON="delete-synonym mutated file after extra operand"
    return 1
  fi
}

run_test_case "prints help" test_shows_help
run_test_case "deletes existing synonym" test_deletes_existing_synonym
run_test_case "fails when synonym not found" test_fails_when_synonym_not_found
run_test_case "rejects empty word" test_rejects_empty_word
run_test_case "deletes literal metacharacter synonym only" test_deletes_literal_metacharacter_synonym_only
run_test_case "rejects extra operands before delete" test_rejects_extra_operands_before_delete


# Test via source-then-invoke pattern  

finish_tests
