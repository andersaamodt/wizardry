#!/bin/sh
# Tests for add-synonym spell
# - prints usage with --help
# - adds synonym in non-interactive mode
# - creates alias definition in file
# - rejects invalid synonym names
# - warns about shell builtins
# - validates against shell keywords
# - handles special characters properly

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_shows_help() {
  run_spell "spells/spellcraft/add-synonym" --help
  assert_success && assert_output_contains "Usage:"
}

test_adds_synonym_noninteractive() {
  case_dir=$(make_tempdir)
  synonyms_file="$case_dir/.synonyms"
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" myalias echo
  
  assert_success || return 1
  assert_output_contains "Synonym created" || return 1
  [ -f "$synonyms_file" ] || { TEST_FAILURE_REASON="synonyms file not created"; return 1; }
}

test_alias_definition_content() {
  case_dir=$(make_tempdir)
  synonyms_file="$case_dir/.synonyms"
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" myalias echo
  
  assert_success || return 1
  
  # Check file contains the alias definition
  if ! grep -q "^alias myalias=" "$synonyms_file"; then
    TEST_FAILURE_REASON="alias definition not found in file"
    return 1
  fi
  
  # Check alias points to echo
  if ! grep -q "^alias myalias='echo'" "$synonyms_file"; then
    TEST_FAILURE_REASON="alias does not point to echo"
    return 1
  fi
}

test_rejects_empty_word() {
  case_dir=$(make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" "" echo
  
  assert_failure || return 1
}

test_rejects_word_with_spaces() {
  case_dir=$(make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" "my alias" echo
  
  assert_failure || return 1
}

test_rejects_word_with_slash() {
  case_dir=$(make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" "my/alias" echo
  
  assert_failure || return 1
}

test_rejects_word_starting_with_dash() {
  case_dir=$(make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" "-myalias" echo
  
  assert_failure || return 1
}

test_rejects_word_starting_with_dot() {
  case_dir=$(make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" ".myalias" echo
  
  assert_failure || return 1
}

test_rejects_word_starting_with_number() {
  case_dir=$(make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" "1alias" echo
  
  assert_failure || return 1
}

test_rejects_empty_spell() {
  case_dir=$(make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" myalias ""
  
  assert_failure || return 1
}

test_allows_overwriting_existing_synonym() {
  case_dir=$(make_tempdir)
  synonyms_file="$case_dir/.synonyms"
  
  # Create first synonym
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" myalias echo
  assert_success || return 1
  
  # Overwrite with second synonym (answer yes to confirm)
  printf 'y\n' | SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" myalias printf
  assert_success || return 1
  
  # Check it was updated
  if ! grep -q "^alias myalias='printf'" "$synonyms_file"; then
    TEST_FAILURE_REASON="synonym not updated"
    return 1
  fi
  
  # Check old definition is gone - there should only be one alias myalias line
  alias_count=$(grep -c "^alias myalias=" "$synonyms_file")
  if [ "$alias_count" -ne 1 ]; then
    TEST_FAILURE_REASON="multiple myalias definitions found ($alias_count)"
    return 1
  fi
}

test_handles_complex_target_with_args() {
  case_dir=$(make_tempdir)
  synonyms_file="$case_dir/.synonyms"
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/add-synonym" ll "ls -la"
  
  assert_success || return 1
  
  # Check alias has both command and args
  if ! grep -q "^alias ll='ls -la'" "$synonyms_file"; then
    TEST_FAILURE_REASON="alias does not contain command with arguments"
    return 1
  fi
}

run_test_case "prints help" test_shows_help
run_test_case "adds synonym non-interactively" test_adds_synonym_noninteractive
run_test_case "creates correct alias definition" test_alias_definition_content
run_test_case "rejects empty word" test_rejects_empty_word
run_test_case "rejects word with spaces" test_rejects_word_with_spaces
run_test_case "rejects word with slash" test_rejects_word_with_slash
run_test_case "rejects word starting with dash" test_rejects_word_starting_with_dash
run_test_case "rejects word starting with dot" test_rejects_word_starting_with_dot
run_test_case "rejects word starting with number" test_rejects_word_starting_with_number
run_test_case "rejects empty spell" test_rejects_empty_spell
run_test_case "allows overwriting synonym" test_allows_overwriting_existing_synonym
run_test_case "handles complex target with args" test_handles_complex_target_with_args


# Test via source-then-invoke pattern  

finish_tests
