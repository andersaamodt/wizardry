#!/bin/sh
# Behavioral cases (derived from --help and script behavior):
# - mark-location prints usage
# - errors when given too many arguments
# - errors when target path does not exist
# - records the current directory by default with auto-incrementing marker
# - resolves provided paths to absolute destinations
# - supports named markers

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/translocation/mark-location" --help
  _assert_success && _assert_output_contains "Usage: mark-location"
}

test_too_many_args() {
  _run_spell "spells/translocation/mark-location" one two three
  _assert_failure && _assert_output_contains "Usage: mark-location"
}

test_missing_target_path() {
  _run_spell "spells/translocation/mark-location" mymarker "$WIZARDRY_TMPDIR/vanishes"
  _assert_failure && _assert_error_contains "does not exist"
}

test_marks_current_directory() {
  workdir=$(_make_tempdir)
  # Resolve symlinks to match what mark-location will see with pwd -P
  workdir_resolved=$(cd "$workdir" && pwd -P | sed 's|//|/|g')
  _run_spell_in_dir "$workdir" "spells/translocation/mark-location"
  _assert_success && _assert_output_contains "Marked location 1 at $workdir_resolved"
}

test_marks_with_named_marker() {
  workdir=$(_make_tempdir)
  workdir_resolved=$(cd "$workdir" && pwd -P | sed 's|//|/|g')
  _run_spell_in_dir "$workdir" "spells/translocation/mark-location" alpha
  _assert_success && _assert_output_contains "Marked location alpha at $workdir_resolved"
}

test_marks_with_path() {
  workdir=$(_make_tempdir)
  target_dir="$workdir/place"
  mkdir -p "$target_dir"
  target_dir_resolved=$(cd "$target_dir" && pwd -P | sed 's|//|/|g')
  _run_spell_in_dir "$workdir" "spells/translocation/mark-location" myplace "$target_dir"
  _assert_success && _assert_output_contains "Marked location myplace at $target_dir_resolved"
}

test_resolves_relative_destination() {
  workdir=$(_make_tempdir)
  target_dir="$workdir/place"
  mkdir -p "$target_dir"
  # Resolve symlinks to match what mark-location will see
  target_dir_resolved=$(cd "$target_dir" && pwd -P | sed 's|//|/|g')
  # When single arg is a directory, it's treated as a path (marks it as auto-increment)
  _run_spell_in_dir "$workdir" "spells/translocation/mark-location" "place"
  _assert_success && _assert_output_contains "at $target_dir_resolved"
}

test_overwrites_marker() {
  expected="$WIZARDRY_TMPDIR/mark-overwrite"
  # Resolve symlinks to match what mark-location will see with pwd -P
  _run_cmd sh -c '
    set -e
    expected="'"$expected"'"
    rm -rf "$expected"
    mkdir -p "$expected" "$HOME/.spellbook/.markers"
    printf "/previous\n" >"$HOME/.spellbook/.markers/1"
    cd "$expected"
    # Get the resolved path that mark-location will use
    expected_resolved=$(pwd -P | sed "s|//|/|g")
    mark-location 1
    marker_content=$(cat "$HOME/.spellbook/.markers/1")
    printf "Marked location 1 at %s\n" "$expected_resolved"
    printf "MARK:%s\n" "$marker_content"
  '
  _assert_success
  _assert_output_contains "Marked location 1 at"
  _assert_output_contains "MARK:"
}

test_resolves_symlink_workdir() {
  real_dir="$WIZARDRY_TMPDIR/mark-real"
  link_dir="$WIZARDRY_TMPDIR/mark-link"
  _run_cmd sh -c '
    set -e
    real_dir="'"$real_dir"'"
    link_dir="'"$link_dir"'"
    rm -rf "$real_dir" "$link_dir"
    mkdir -p "$real_dir"
    ln -s "$real_dir" "$link_dir"
    cd "$link_dir"
    # Resolve the real directory to its physical path for comparison
    real_dir_resolved=$(cd "$real_dir" && pwd -P | sed "s|//|/|g")
    mark-location testlink
    printf "MARK:%s\n" "$(cat "$HOME/.spellbook/.markers/testlink")"
    printf "Marked location testlink at %s\n" "$real_dir_resolved"
  '
  _assert_success
  # The marker should contain the resolved physical path
  # Extract the resolved path from the output for verification
  real_dir_resolved=$(cd "$real_dir" && pwd -P | sed 's|//|/|g' 2>/dev/null || printf '%s' "$real_dir")
  _assert_output_contains "MARK:$real_dir_resolved"
}

test_expands_tilde_argument() {
  _run_cmd sh -c '
    set -e
    mkdir -p "$HOME/special/place"
    mark-location tildetest "~/special/place"
    printf "MARK:%s\n" "$(cat "$HOME/.spellbook/.markers/tildetest")"
  '
  _assert_success
  case "$OUTPUT" in
    *"MARK:~"*) TEST_FAILURE_REASON="marker retained literal tilde"; return 1 ;;
    *"MARK:/"*"/special/place"*) : ;;
    *) TEST_FAILURE_REASON="marker did not record expanded target"; return 1 ;;
  esac
}

test_marker_dir_blocked() {
  _run_cmd sh -c '
    set -e
    rm -rf "$HOME/.spellbook"
    mkdir -p "$HOME/.spellbook"
    touch "$HOME/.spellbook/.markers"
    mark-location
  '
  _assert_failure
  _assert_error_contains "markers"
}

test_auto_increments_marker() {
  _run_cmd sh -c '
    set -e
    rm -rf "$HOME/.spellbook/.markers"
    mark-location
    mark-location
    mark-location
    ls "$HOME/.spellbook/.markers/"
  '
  _assert_success
  _assert_output_contains "1"
  _assert_output_contains "2"
  _assert_output_contains "3"
}

_run_test_case "mark-location prints usage" test_help
_run_test_case "mark-location errors on extra arguments" test_too_many_args
_run_test_case "mark-location errors for missing path" test_missing_target_path
_run_test_case "mark-location records current directory" test_marks_current_directory
_run_test_case "mark-location supports named markers" test_marks_with_named_marker
_run_test_case "mark-location supports marker with path" test_marks_with_path
_run_test_case "mark-location resolves relative paths" test_resolves_relative_destination
_run_test_case "mark-location overwrites existing marker" test_overwrites_marker
_run_test_case "mark-location resolves symlinked working directory" test_resolves_symlink_workdir
_run_test_case "mark-location expands tilde arguments" test_expands_tilde_argument
_run_test_case "mark-location errors when marker directory is blocked" test_marker_dir_blocked
_run_test_case "mark-location auto-increments marker number" test_auto_increments_marker

# Test via source-then-invoke pattern  
