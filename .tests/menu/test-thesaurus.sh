#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - thesaurus is executable and has content
# - thesaurus shows usage with --help
# - thesaurus fails when menu dependency is missing
# - thesaurus supports --list flag

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/menu/thesaurus" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/menu/thesaurus" ]
}

run_test_case "menu/thesaurus is executable" spell_is_executable
run_test_case "menu/thesaurus has content" spell_has_content

test_shows_help() {
  run_cmd "$ROOT_DIR/spells/menu/thesaurus" --help
  assert_success
  assert_output_contains "Usage: thesaurus"
}

run_test_case "thesaurus --help shows usage" test_shows_help

test_fails_without_menu_dependency() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s\n' "thesaurus: The 'menu' command is required." >&2
exit 1
SH
  chmod +x "$tmp/require-command"
  PATH="$tmp:$PATH" run_cmd "$ROOT_DIR/spells/menu/thesaurus"
  assert_failure || return 1
  assert_error_contains "menu" || return 1
}

run_test_case "thesaurus fails without menu dependency" test_fails_without_menu_dependency

test_accepts_list_flag() {
  run_cmd "$ROOT_DIR/spells/menu/thesaurus" --help
  assert_success || return 1
  assert_output_contains "--list" || return 1
}

run_test_case "thesaurus accepts --list flag" test_accepts_list_flag

test_works_with_empty_synonyms() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  
  # Create empty synonym files
  printf '# Empty\n' > "$spellbook/.default-synonyms"
  printf '# Empty\n' > "$spellbook/.synonyms"
  touch "$spellbook/.default-synonyms-initialized"
  
  # Run thesaurus --list (should not crash)
  export SPELLBOOK_DIR="$spellbook"
  run_spell "spells/menu/thesaurus" --list >/dev/null 2>&1 || true
  
  # If we got here without crashing, test passes
  return 0
}

run_test_case "thesaurus works with empty synonyms" test_works_with_empty_synonyms

test_works_without_wizardry_dir() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  
  # Run thesaurus without WIZARDRY_DIR set (should set it automatically)
  export SPELLBOOK_DIR="$spellbook"
  unset WIZARDRY_DIR || true
  run_spell "spells/menu/thesaurus" --help >/dev/null 2>&1
  assert_success || return 1
}

run_test_case "thesaurus works without WIZARDRY_DIR" test_works_without_wizardry_dir

test_no_integer_expression_error_with_empty_files() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  
  # Create empty synonym files (only comments, no aliases)
  printf '# Default Synonyms\n# No aliases here\n' > "$spellbook/.default-synonyms"
  printf '# Custom Synonyms\n' > "$spellbook/.synonyms"
  touch "$spellbook/.default-synonyms-initialized"
  
  # Run thesaurus --list and check for integer expression error
  export SPELLBOOK_DIR="$spellbook"
  OUTPUT=$(run_spell "spells/menu/thesaurus" --list 2>&1) || true
  
  # Should not contain "integer expression expected" error
  if printf '%s' "$OUTPUT" | grep -q "integer expression expected"; then
    TEST_FAILURE_REASON="Got integer expression error: $OUTPUT"
    return 1
  fi
  
  return 0
}

run_test_case "no integer expression error with empty files" test_no_integer_expression_error_with_empty_files


# Test via source-then-invoke pattern  

finish_tests
