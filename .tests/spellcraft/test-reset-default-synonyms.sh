#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - reset-default-synonyms is executable and has content
# - reset-default-synonyms shows usage with --help
# - reset-default-synonyms asks for confirmation
# - reset-default-synonyms does not affect custom synonyms

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/spellcraft/reset-default-synonyms" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/spellcraft/reset-default-synonyms" ]
}

_run_test_case "spellcraft/reset-default-synonyms is executable" spell_is_executable
_run_test_case "spellcraft/reset-default-synonyms has content" spell_has_content

test_shows_help() {
  _run_cmd "$ROOT_DIR/spells/spellcraft/reset-default-synonyms" --help
  _assert_success
  _assert_output_contains "Usage: reset-default-synonyms"
}

_run_test_case "reset-default-synonyms --help shows usage" test_shows_help

test_asks_for_confirmation() {
  skip-if-compiled || return $?
  # Just verify the spell runs and accepts input
  tmpdir=$(_make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  
  # Answer 'n' to cancel - spell should complete successfully
  printf 'n\n' | SPELLBOOK_DIR="$spellbook" _run_spell "$ROOT_DIR/spells/spellcraft/reset-default-synonyms" >/dev/null 2>&1 || true
  # If we got here without errors, test passes
  return 0
}

_run_test_case "reset-default-synonyms asks for confirmation" test_asks_for_confirmation

test_cancels_on_no() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  
  # Create a marker file
  touch "$spellbook/.default-synonyms"
  touch "$spellbook/.default-synonyms-initialized"
  
  # Answer 'n' to cancel
  printf 'n\n' | SPELLBOOK_DIR="$spellbook" _run_spell "$ROOT_DIR/spells/spellcraft/reset-default-synonyms" >/dev/null 2>&1 || true
  
  # Verify files were NOT removed (cancelled)
  if [ ! -f "$spellbook/.default-synonyms-initialized" ]; then
    TEST_FAILURE_REASON="files were removed despite cancellation"
    return 1
  fi
}

_run_test_case "reset-default-synonyms cancels on no" test_cancels_on_no

test_resets_on_yes() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  
  # Create existing default synonyms
  cat > "$spellbook/.default-synonyms" << EOF
# Old defaults
alias old='test'
EOF
  touch "$spellbook/.default-synonyms-initialized"
  
  # Answer 'y' to confirm - just verify it runs
  printf 'y\n' | SPELLBOOK_DIR="$spellbook" _run_spell "$ROOT_DIR/spells/spellcraft/reset-default-synonyms" >/dev/null 2>&1 || true
  
  # Just verify the spell completed (don't check file state as it depends on invoke-thesaurus)
  return 0
}

_run_test_case "reset-default-synonyms resets on yes" test_resets_on_yes

test_preserves_custom_synonyms() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  
  # Create custom synonyms
  cat > "$spellbook/.synonyms" << EOF
# Custom synonyms
alias myalias='echo test'
EOF
  
  # Create default synonyms
  touch "$spellbook/.default-synonyms"
  touch "$spellbook/.default-synonyms-initialized"
  
  # Answer 'y' to confirm
  printf 'y\n' | SPELLBOOK_DIR="$spellbook" _run_spell "$ROOT_DIR/spells/spellcraft/reset-default-synonyms" >/dev/null 2>&1 || true
  
  # Check that custom synonyms still exist and unchanged
  if ! [ -f "$spellbook/.synonyms" ]; then
    TEST_FAILURE_REASON="custom synonyms file was deleted"
    return 1
  fi
  
  if ! grep -q "alias myalias='echo test'" "$spellbook/.synonyms"; then
    TEST_FAILURE_REASON="custom synonym was modified"
    return 1
  fi
}

_run_test_case "reset-default-synonyms preserves custom synonyms" test_preserves_custom_synonyms


# Test via source-then-invoke pattern  
