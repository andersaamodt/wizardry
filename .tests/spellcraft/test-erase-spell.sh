#!/bin/sh
# erase-spell test coverage:
# - shows usage with --help
# - rejects unknown options
# - requires spell name argument
# - errors when spell not found
# - --force skips confirmation and deletes spell

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

make_spellbook_dir() {
  dir=$(mktemp -d "$WIZARDRY_TMPDIR/spellbook.XXXXXX") || exit 1
  printf '%s\n' "$dir"
}

test_shows_usage_with_help() {
  run_spell "spells/spellcraft/erase-spell" --help
  assert_success || return 1
  case "$OUTPUT" in
    *"Usage: erase-spell"*) : ;;
    *) TEST_FAILURE_REASON="help text should show usage: $OUTPUT"; return 1 ;;
  esac
}

test_requires_spell_name() {
  run_spell "spells/spellcraft/erase-spell"
  assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"Usage:"*) : ;;
    *) TEST_FAILURE_REASON="should show usage when no arguments: $OUTPUT$ERROR"; return 1 ;;
  esac
}

test_errors_when_spell_not_found() {
  spellbook_dir=$(make_spellbook_dir)
  SPELLBOOK_DIR="$spellbook_dir" run_spell "spells/spellcraft/erase-spell" nonexistent
  assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"not found"*) : ;;
    *) TEST_FAILURE_REASON="should report spell not found: $OUTPUT$ERROR"; return 1 ;;
  esac
}

test_force_deletes_spell_without_confirmation() {
  spellbook_dir=$(make_spellbook_dir)
  # Create a custom spell
  printf '#!/bin/sh\necho hello\n' >"$spellbook_dir/test-spell"
  chmod +x "$spellbook_dir/test-spell"
  # Delete with --force
  SPELLBOOK_DIR="$spellbook_dir" run_spell "spells/spellcraft/erase-spell" --force test-spell
  assert_success || return 1
  case "$OUTPUT" in
    *"Erased spell"*) : ;;
    *) TEST_FAILURE_REASON="should confirm deletion: $OUTPUT"; return 1 ;;
  esac
  # Verify file is removed
  if [ -f "$spellbook_dir/test-spell" ]; then
    TEST_FAILURE_REASON="spell file should be deleted"
    return 1
  fi
}

test_force_deletes_spell_in_subfolder() {
  spellbook_dir=$(make_spellbook_dir)
  mkdir -p "$spellbook_dir/category"
  # Create a custom spell in subfolder
  printf '#!/bin/sh\necho hello\n' >"$spellbook_dir/category/sub-spell"
  chmod +x "$spellbook_dir/category/sub-spell"
  # Delete with --force
  SPELLBOOK_DIR="$spellbook_dir" run_spell "spells/spellcraft/erase-spell" --force sub-spell
  assert_success || return 1
  # Verify file is removed
  if [ -f "$spellbook_dir/category/sub-spell" ]; then
    TEST_FAILURE_REASON="spell file should be deleted"
    return 1
  fi
}

test_unknown_option() {
  run_spell "spells/spellcraft/erase-spell" --unknown
  assert_failure || return 1
  assert_error_contains "unknown option" || return 1
}

run_test_case "erase-spell shows usage with --help" test_shows_usage_with_help
run_test_case "erase-spell rejects unknown option" test_unknown_option
run_test_case "erase-spell requires spell name" test_requires_spell_name
run_test_case "erase-spell errors when spell not found" test_errors_when_spell_not_found
run_test_case "erase-spell --force deletes without confirmation" test_force_deletes_spell_without_confirmation
run_test_case "erase-spell --force deletes spell in subfolder" test_force_deletes_spell_in_subfolder

finish_tests
