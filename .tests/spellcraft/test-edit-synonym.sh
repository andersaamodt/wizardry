#!/bin/sh
# Tests for edit-synonym spell
# - prints usage with --help
# - edits synonym word (renames)
# - edits target spell
# - fails when synonym doesn't exist
# - validates new word name
# - prevents duplicate word names

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_shows_help() {
  run_spell "spells/spellcraft/edit-synonym" --help
  assert_success && assert_output_contains "Usage:"
}

test_edits_synonym_word() {
  skip-if-compiled || return $?
  case_dir=$(make_tempdir)
  synonyms_file="$case_dir/.synonyms"
  
  # Create a synonym first
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" oldalias echo
  assert_success || return 1
  
  # Rename it
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/edit-synonym" oldalias --word newalias
  
  assert_success || return 1
  
  # Verify old alias is gone
  if grep -q "^alias oldalias=" "$synonyms_file"; then
    TEST_FAILURE_REASON="old synonym still exists"
    return 1
  fi
  
  # Verify new alias exists
  if ! grep -q "^alias newalias=" "$synonyms_file"; then
    TEST_FAILURE_REASON="new synonym not created"
    return 1
  fi
}

test_edits_target_spell() {
  skip-if-compiled || return $?
  case_dir=$(make_tempdir)
  synonyms_file="$case_dir/.synonyms"
  
  # Create a synonym first
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" myalias echo
  assert_success || return 1
  
  # Change target spell
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/edit-synonym" myalias --spell printf
  
  assert_success || return 1
  
  # Verify new target
  if ! grep -q "^alias myalias='printf'" "$synonyms_file"; then
    TEST_FAILURE_REASON="target spell not updated"
    return 1
  fi
}

test_fails_when_synonym_not_found() {
  case_dir=$(make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/edit-synonym" nonexistent --word newalias
  
  assert_failure || return 1
}

test_requires_edit_mode() {
  case_dir=$(make_tempdir)
  
  # Create a synonym first
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" myalias echo
  assert_success || return 1
  
  # Try to edit without --word or --spell
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/edit-synonym" myalias
  
  assert_failure || return 1
}

test_rejects_invalid_new_word() {
  case_dir=$(make_tempdir)
  
  # Create a synonym first
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" myalias echo
  assert_success || return 1
  
  # Try to rename with spaces
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/edit-synonym" myalias --word "new alias"
  
  assert_failure || return 1
}

test_prevents_duplicate_word() {
  case_dir=$(make_tempdir)
  
  # Create two synonyms
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" alias1 echo
  assert_success || return 1
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" alias2 printf
  assert_success || return 1
  
  # Try to rename alias1 to alias2 (should fail)
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/edit-synonym" alias1 --word alias2
  
  assert_failure || return 1
}

run_test_case "prints help" test_shows_help
run_test_case "edits synonym word" test_edits_synonym_word
run_test_case "edits target spell" test_edits_target_spell
run_test_case "fails when synonym not found" test_fails_when_synonym_not_found
run_test_case "requires edit mode flag" test_requires_edit_mode
run_test_case "rejects invalid new word" test_rejects_invalid_new_word
run_test_case "prevents duplicate word" test_prevents_duplicate_word


# Test via source-then-invoke pattern  

finish_tests
