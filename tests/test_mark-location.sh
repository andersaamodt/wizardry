#!/bin/sh
# Behavioral cases (derived from --help and script behavior):
# - mark-location prints usage
# - errors when given too many arguments
# - errors when target path does not exist
# - records the current directory by default
# - resolves provided paths to absolute destinations

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/mark-location" --help
  assert_success && assert_output_contains "Usage: mark-location"
}

test_too_many_args() {
  run_spell "spells/mark-location" one two
  assert_failure && assert_output_contains "Usage: mark-location"
}

test_missing_target_path() {
  run_spell "spells/mark-location" "$WIZARDRY_TMPDIR/vanishes"
  assert_failure && assert_error_contains "does not exist"
}

test_marks_current_directory() {
  workdir=$(make_tempdir)
  run_spell_in_dir "$workdir" "spells/mark-location"
  assert_success && assert_output_contains "Location marked at $workdir"
}

test_resolves_relative_destination() {
  workdir=$(make_tempdir)
  target_dir="$workdir/place"
  mkdir -p "$target_dir"
  run_spell_in_dir "$workdir" "spells/mark-location" "place"
  assert_success && assert_output_contains "Location marked at $target_dir"
}

run_test_case "mark-location prints usage" test_help
run_test_case "mark-location errors on extra arguments" test_too_many_args
run_test_case "mark-location errors for missing path" test_missing_target_path
run_test_case "mark-location records current directory" test_marks_current_directory
run_test_case "mark-location resolves relative paths" test_resolves_relative_destination
finish_tests
