#!/bin/sh
# Tests for add-synonym spell
# - prints usage with --help
# - adds synonym in non-interactive mode
# - creates executable synonym script
# - synonym forwards arguments correctly
# - rejects invalid synonym names
# - warns about conflicts with existing commands
# - warns about missing target spells

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_shows_help() {
  _run_spell "spells/spellcraft/add-synonym" --help
  _assert_success && _assert_output_contains "Usage:"
}

test_adds_synonym_noninteractive() {
  case_dir=$(_make_tempdir)
  synonyms_dir="$case_dir/.synonyms"
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" myalias echo
  
  _assert_success || return 1
  _assert_output_contains "Synonym created" || return 1
  [ -x "$synonyms_dir/myalias" ] || { TEST_FAILURE_REASON="synonym not created"; return 1; }
}

test_synonym_script_content() {
  case_dir=$(_make_tempdir)
  synonyms_dir="$case_dir/.synonyms"
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" myalias echo
  
  _assert_success || return 1
  
  # Check script contains the target spell
  script_content=$(cat "$synonyms_dir/myalias")
  case "$script_content" in
    *"exec 'echo'"*) : ;;
    *) TEST_FAILURE_REASON="script missing exec statement: $script_content"; return 1 ;;
  esac
  
  # Check for synonym marker comment
  case "$script_content" in
    *"# Synonym:"*) : ;;
    *) TEST_FAILURE_REASON="script missing synonym marker"; return 1 ;;
  esac
}

test_synonym_forwards_arguments() {
  case_dir=$(_make_tempdir)
  synonyms_dir="$case_dir/.synonyms"
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" myecho printf
  
  _assert_success || return 1
  
  # Test that the synonym works
  PATH="$synonyms_dir:$PATH" output=$("$synonyms_dir/myecho" "test message")
  case "$output" in
    *"test message"*) : ;;
    *) TEST_FAILURE_REASON="synonym did not forward arguments correctly: $output"; return 1 ;;
  esac
}

test_rejects_empty_word() {
  case_dir=$(_make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" "" echo
  
  _assert_failure || return 1
}

test_rejects_word_with_spaces() {
  case_dir=$(_make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" "my alias" echo
  
  _assert_failure || return 1
}

test_rejects_word_with_slash() {
  case_dir=$(_make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" "my/alias" echo
  
  _assert_failure || return 1
}

test_rejects_word_starting_with_dash() {
  case_dir=$(_make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" "-myalias" echo
  
  _assert_failure || return 1
}

test_rejects_word_starting_with_dot() {
  case_dir=$(_make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" ".myalias" echo
  
  _assert_failure || return 1
}

test_rejects_empty_spell() {
  case_dir=$(_make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" myalias ""
  
  _assert_failure || return 1
}

test_allows_overwriting_existing_synonym() {
  case_dir=$(_make_tempdir)
  synonyms_dir="$case_dir/.synonyms"
  
  # Create first synonym
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" myalias echo
  _assert_success || return 1
  
  # Overwrite with second synonym
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" myalias printf
  _assert_success || return 1
  
  # Check it was updated
  script_content=$(cat "$synonyms_dir/myalias")
  case "$script_content" in
    *"exec 'printf'"*) : ;;
    *) TEST_FAILURE_REASON="synonym not updated"; return 1 ;;
  esac
}

_run_test_case "prints help" test_shows_help
_run_test_case "adds synonym non-interactively" test_adds_synonym_noninteractive
_run_test_case "creates correct script content" test_synonym_script_content
_run_test_case "synonym forwards arguments" test_synonym_forwards_arguments
_run_test_case "rejects empty word" test_rejects_empty_word
_run_test_case "rejects word with spaces" test_rejects_word_with_spaces
_run_test_case "rejects word with slash" test_rejects_word_with_slash
_run_test_case "rejects word starting with dash" test_rejects_word_starting_with_dash
_run_test_case "rejects word starting with dot" test_rejects_word_starting_with_dot
_run_test_case "rejects empty spell" test_rejects_empty_spell
_run_test_case "allows overwriting synonym" test_allows_overwriting_existing_synonym

_finish_tests
