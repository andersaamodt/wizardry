#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.wizardry/validate-spells" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
}

test_validate_existing_spells() {
  WIZARDRY_DIR="$ROOT_DIR" run_spell "spells/.wizardry/validate-spells" "banish:wards"
  assert_success || return 1
  assert_output_contains "Found spell: banish" || return 1
}

test_validate_existing_imps() {
  WIZARDRY_DIR="$ROOT_DIR" run_spell "spells/.wizardry/validate-spells" --imps "cond/has" "out/say"
  assert_success || return 1
  assert_output_contains "Found imp: cond/has" || return 1
  assert_output_contains "Found imp: out/say" || return 1
}

test_validate_missing_spells() {
  WIZARDRY_DIR="$ROOT_DIR" run_spell "spells/.wizardry/validate-spells" "nonexistent-spell"
  assert_failure || return 1
  if ! printf '%s' "$OUTPUT" | grep -q "Missing Spell: nonexistent-spell" && \
    ! printf '%s' "$ERROR" | grep -q "Missing Spell: nonexistent-spell"; then
    TEST_FAILURE_REASON="missing spell message not found in output"
    return 1
  fi
}

test_missing_only_flag() {
  WIZARDRY_DIR="$ROOT_DIR" run_spell "spells/.wizardry/validate-spells" --missing-only "nonexistent-spell"
  assert_failure || return 1
  assert_output_contains "nonexistent-spell" || return 1
  # Should not contain "Missing spells:" prefix with --missing-only
  ! assert_output_contains "Missing spells:" 2>/dev/null || return 1
}

test_show_status_unloaded() {
  # When imps are not loaded, they should show as "Available"
  WIZARDRY_DIR="$ROOT_DIR" run_spell "spells/.wizardry/validate-spells" --imps --show-status "cond/has" "out/say"
  assert_success || return 1
  assert_output_contains "Imps: has say" || return 1
}

test_show_status_loaded() {
  # In flat-file paradigm, spells/imps are always "available" as scripts
  # This test is no longer applicable since we don't preload functions
  # Just test that --show-status works correctly
  WIZARDRY_DIR="$ROOT_DIR" run_spell "spells/.wizardry/validate-spells" --imps --show-status "cond/has" "out/say"
  assert_success || return 1
  # In flat-file paradigm, all imps show as "Imps:" (not "Loaded")
  assert_output_contains "Imps:" || return 1
  
  return 0
}

test_quiet_flag() {
  WIZARDRY_DIR="$ROOT_DIR" run_spell "spells/.wizardry/validate-spells" --quiet "banish:wards"
  assert_success || return 1
  # Quiet should suppress "Found spell" messages
  [ -z "$OUTPUT" ] || return 1
}

run_test_case "validate-spells prints help" test_help
run_test_case "validate-spells finds existing spells" test_validate_existing_spells
run_test_case "validate-spells finds existing imps" test_validate_existing_imps
run_test_case "validate-spells reports missing spells" test_validate_missing_spells
run_test_case "validate-spells --missing-only returns list" test_missing_only_flag
run_test_case "validate-spells --show-status shows unloaded imps" test_show_status_unloaded
run_test_case "validate-spells --show-status shows loaded imps" test_show_status_loaded
run_test_case "validate-spells --quiet suppresses output" test_quiet_flag

finish_tests
