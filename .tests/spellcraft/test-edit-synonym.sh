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
  _run_spell "spells/spellcraft/edit-synonym" --help
  _assert_success && _assert_output_contains "Usage:"
}

test_edits_synonym_word() {
  case_dir=$(_make_tempdir)
  synonyms_dir="$case_dir/.synonyms"
  
  # Create a synonym first
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" oldalias echo
  _assert_success || return 1
  
  # Rename it
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/edit-synonym" oldalias --word newalias
  
  _assert_success || return 1
  [ ! -f "$synonyms_dir/oldalias" ] || { TEST_FAILURE_REASON="old synonym still exists"; return 1; }
  [ -f "$synonyms_dir/newalias" ] || { TEST_FAILURE_REASON="new synonym not created"; return 1; }
}

test_edits_target_spell() {
  case_dir=$(_make_tempdir)
  synonyms_dir="$case_dir/.synonyms"
  
  # Create a synonym first
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" myalias echo
  _assert_success || return 1
  
  # Change target spell
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/edit-synonym" myalias --spell printf
  
  _assert_success || return 1
  
  # Verify new target
  script_content=$(cat "$synonyms_dir/myalias")
  case "$script_content" in
    *"exec 'printf'"*) : ;;
    *) TEST_FAILURE_REASON="target spell not updated"; return 1 ;;
  esac
}

test_fails_when_synonym_not_found() {
  case_dir=$(_make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/edit-synonym" nonexistent --word newalias
  
  _assert_failure || return 1
}

test_requires_edit_mode() {
  case_dir=$(_make_tempdir)
  
  # Create a synonym first
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" myalias echo
  _assert_success || return 1
  
  # Try to edit without --word or --spell
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/edit-synonym" myalias
  
  _assert_failure || return 1
}

test_rejects_invalid_new_word() {
  case_dir=$(_make_tempdir)
  
  # Create a synonym first
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" myalias echo
  _assert_success || return 1
  
  # Try to rename with spaces
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/edit-synonym" myalias --word "new alias"
  
  _assert_failure || return 1
}

test_prevents_duplicate_word() {
  case_dir=$(_make_tempdir)
  
  # Create two synonyms
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" alias1 echo
  _assert_success || return 1
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" alias2 printf
  _assert_success || return 1
  
  # Try to rename alias1 to alias2 (should fail)
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/edit-synonym" alias1 --word alias2
  
  _assert_failure || return 1
}

_run_test_case "prints help" test_shows_help
_run_test_case "edits synonym word" test_edits_synonym_word
_run_test_case "edits target spell" test_edits_target_spell
_run_test_case "fails when synonym not found" test_fails_when_synonym_not_found
_run_test_case "requires edit mode flag" test_requires_edit_mode
_run_test_case "rejects invalid new word" test_rejects_invalid_new_word
_run_test_case "prevents duplicate word" test_prevents_duplicate_word

_finish_tests
