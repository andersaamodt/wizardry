#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - synonym-menu is executable and has content
# - synonym-menu shows usage with --help
# - synonym-menu requires WORD argument
# - synonym-menu auto-detects synonym type

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/menu/synonym-menu" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/menu/synonym-menu" ]
}

run_test_case "menu/synonym-menu is executable" spell_is_executable
run_test_case "menu/synonym-menu has content" spell_has_content

test_shows_help() {
  run_cmd "$ROOT_DIR/spells/menu/synonym-menu" --help
  assert_success
  assert_output_contains "Usage: synonym-menu"
}

run_test_case "synonym-menu --help shows usage" test_shows_help

test_requires_word_argument() {
  run_cmd "$ROOT_DIR/spells/menu/synonym-menu"
  assert_failure || return 1
  assert_error_contains "requires WORD argument" || return 1
}

run_test_case "synonym-menu requires WORD argument" test_requires_word_argument

test_fails_for_nonexistent_synonym() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  
  SPELLBOOK_DIR="$spellbook" run_cmd "$ROOT_DIR/spells/menu/synonym-menu" nonexistent
  assert_failure || return 1
  assert_error_contains "not found" || return 1
}

run_test_case "synonym-menu fails for nonexistent synonym" test_fails_for_nonexistent_synonym

test_detects_custom_synonym() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  
  # Create custom synonym
  cat > "$spellbook/.synonyms" << EOF
# Custom synonyms
alias mytest='echo'
EOF
  
  # Run synonym-menu with the custom synonym
  SPELLBOOK_DIR="$spellbook" run_cmd "$ROOT_DIR/spells/menu/synonym-menu" --help
  assert_success || return 1
  assert_output_contains "Auto-detects" || return 1
}

run_test_case "synonym-menu auto-detects synonym type" test_detects_custom_synonym


# Test via source-then-invoke pattern  
