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

test_overwrites_marker() {
  expected="$WIZARDRY_TMPDIR/mark-overwrite"
  run_cmd sh -c '
    set -e
    expected="$WIZARDRY_TMPDIR/mark-overwrite"
    rm -rf "$expected"
    mkdir -p "$expected" "$HOME/.mud"
    printf "/previous\n" >"$HOME/.mud/portal_marker"
    cd "$expected"
    mark-location
    printf "MARK:%s\n" "$(cat "$HOME/.mud/portal_marker")"
  '
  assert_success
  assert_output_contains "Location marked at $expected"
  assert_output_contains "MARK:$expected"
}

test_resolves_symlink_workdir() {
  real_dir="$WIZARDRY_TMPDIR/mark-real"
  link_dir="$WIZARDRY_TMPDIR/mark-link"
  run_cmd sh -c '
    set -e
    real_dir="$WIZARDRY_TMPDIR/mark-real"
    link_dir="$WIZARDRY_TMPDIR/mark-link"
    rm -rf "$real_dir" "$link_dir"
    mkdir -p "$real_dir"
    ln -s "$real_dir" "$link_dir"
    cd "$link_dir"
    mark-location
    printf "MARK:%s\n" "$(cat "$HOME/.mud/portal_marker")"
  '
  assert_success
  assert_output_contains "Location marked at $real_dir"
  assert_output_contains "MARK:$real_dir"
}

test_expands_tilde_argument() {
  run_cmd sh -c '
    set -e
    mkdir -p "$HOME/special/place"
    mark-location "~/special/place"
    printf "MARK:%s\n" "$(cat "$HOME/.mud/portal_marker")"
  '
  assert_success
  case "$OUTPUT" in
    *"MARK:~"*) TEST_FAILURE_REASON="marker retained literal tilde"; return 1 ;;
    *"MARK:/"*"/special/place"*) : ;;
    *) TEST_FAILURE_REASON="marker did not record expanded target"; return 1 ;;
  esac
}

test_marker_dir_blocked() {
  run_cmd sh -c '
    set -e
    touch "$HOME/.mud"
    mark-location
  '
  assert_failure
  assert_error_contains ".mud"
}

run_test_case "mark-location prints usage" test_help
run_test_case "mark-location errors on extra arguments" test_too_many_args
run_test_case "mark-location errors for missing path" test_missing_target_path
run_test_case "mark-location records current directory" test_marks_current_directory
run_test_case "mark-location resolves relative paths" test_resolves_relative_destination
run_test_case "mark-location overwrites existing marker" test_overwrites_marker
run_test_case "mark-location resolves symlinked working directory" test_resolves_symlink_workdir
run_test_case "mark-location expands tilde arguments" test_expands_tilde_argument
run_test_case "mark-location errors when marker directory is blocked" test_marker_dir_blocked
finish_tests
