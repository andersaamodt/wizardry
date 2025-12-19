#!/bin/sh
# Tests for init-synonyms spell
# - creates default synonyms
# - creates synonyms directory
# - marks initialization as done
# - does not overwrite existing synonyms

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_default_synonyms() {
  case_dir=$(_make_tempdir)
  synonyms_dir="$case_dir/.synonyms"
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/init-synonyms"
  
  _assert_success || return 1
  
  # Check that default synonyms were created
  [ -f "$synonyms_dir/detect-os" ] || { TEST_FAILURE_REASON="detect-os not created"; return 1; }
  [ -f "$synonyms_dir/home" ] || { TEST_FAILURE_REASON="home not created"; return 1; }
}

test_creates_synonyms_directory() {
  case_dir=$(_make_tempdir)
  synonyms_dir="$case_dir/.synonyms"
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/init-synonyms"
  
  _assert_success || return 1
  [ -d "$synonyms_dir" ] || { TEST_FAILURE_REASON="synonyms directory not created"; return 1; }
}

test_marks_initialization_done() {
  case_dir=$(_make_tempdir)
  synonyms_dir="$case_dir/.synonyms"
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/init-synonyms"
  
  _assert_success || return 1
  [ -f "$synonyms_dir/.initialized" ] || { TEST_FAILURE_REASON="initialization marker not created"; return 1; }
}

test_does_not_overwrite_existing() {
  case_dir=$(_make_tempdir)
  synonyms_dir="$case_dir/.synonyms"
  
  # Create a custom detect-os synonym first
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/add-synonym" detect-os custom-command
  _assert_success || return 1
  
  # Run init-synonyms
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/init-synonyms"
  _assert_success || return 1
  
  # Verify the custom synonym was not overwritten
  script_content=$(cat "$synonyms_dir/detect-os")
  case "$script_content" in
    *"custom-command"*) : ;;
    *) TEST_FAILURE_REASON="existing synonym was overwritten"; return 1 ;;
  esac
}

test_default_synonym_content() {
  case_dir=$(_make_tempdir)
  synonyms_dir="$case_dir/.synonyms"
  
  SPELLBOOK_DIR="$case_dir" \
    _run_spell "spells/spellcraft/init-synonyms"
  
  _assert_success || return 1
  
  # Check detect-os points to detect-distro
  script_content=$(cat "$synonyms_dir/detect-os")
  case "$script_content" in
    *"detect-distro"*) : ;;
    *) TEST_FAILURE_REASON="detect-os does not point to detect-distro"; return 1 ;;
  esac
  
  # Check home points to cd
  script_content=$(cat "$synonyms_dir/home")
  case "$script_content" in
    *"'cd'"*) : ;;
    *) TEST_FAILURE_REASON="home does not point to cd"; return 1 ;;
  esac
}

_run_test_case "creates default synonyms" test_creates_default_synonyms
_run_test_case "creates synonyms directory" test_creates_synonyms_directory
_run_test_case "marks initialization done" test_marks_initialization_done
_run_test_case "does not overwrite existing" test_does_not_overwrite_existing
_run_test_case "default synonym content correct" test_default_synonym_content

_finish_tests
