#!/bin/sh
# Behavioral cases (derived from --help):
# - jump-to-marker prints usage
# - jump to specific marker
# - jump cycles through markers when called repeatedly
# - jump fails when no markers exist

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Build wizardry base path with all imp directories and cantrips
wizardry_base_path() {
  printf '%s' "$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input"
}

test_help() {
  run_spell "spells/translocation/jump-to-marker" --help
  assert_success && assert_output_contains "Usage:"
}

test_unknown_option_fails() {
  run_cmd sh -c "PATH=\"$WIZARDRY_IMPS_PATH:$(wizardry_base_path):/bin:/usr/bin\" set -- --bad; . \"$ROOT_DIR/spells/translocation/jump-to-marker\""
  assert_failure && assert_error_contains "unknown option"
}

run_jump() {
  marker_arg=${1:-}
  markers_dir=${2:-$WIZARDRY_TMPDIR/markers}
  RUN_CMD_WORKDIR=${3:-$WIZARDRY_TMPDIR}
  PATH="$WIZARDRY_IMPS_PATH:$(wizardry_base_path):/bin:/usr/bin"
  JUMP_TO_MARKERS_DIR="$markers_dir"
  export JUMP_TO_MARKERS_DIR PATH RUN_CMD_WORKDIR
  if [ -n "$marker_arg" ]; then
    run_cmd sh -c "set -- \"$marker_arg\"; . \"$ROOT_DIR/spells/translocation/jump-to-marker\""
  else
    run_cmd sh -c ". \"$ROOT_DIR/spells/translocation/jump-to-marker\""
  fi
}

test_jump_requires_markers_dir() {
  missing_dir="$WIZARDRY_TMPDIR/no-markers"
  rm -rf "$missing_dir"
  run_jump "" "$missing_dir"
  assert_failure && assert_output_contains "No markers have been set"
}

test_jump_requires_specific_marker() {
  markers_dir="$WIZARDRY_TMPDIR/markers-test"
  mkdir -p "$markers_dir"
  run_jump "nonexistent" "$markers_dir"
  assert_failure && assert_output_contains "No marker 'nonexistent' found"
}

test_jump_rejects_blank_marker() {
  markers_dir="$WIZARDRY_TMPDIR/markers-blank"
  mkdir -p "$markers_dir"
  : >"$markers_dir/1"
  run_jump "1" "$markers_dir"
  assert_failure && assert_output_contains "is blank"
}

test_jump_rejects_missing_destination() {
  markers_dir="$WIZARDRY_TMPDIR/markers-missing-dest"
  mkdir -p "$markers_dir"
  printf '%s\n' "$WIZARDRY_TMPDIR/nonexistent" >"$markers_dir/1"
  run_jump "1" "$markers_dir"
  assert_failure && assert_output_contains "no longer exists"
}

test_jump_detects_current_location() {
  destination="$WIZARDRY_TMPDIR/already-here"
  markers_dir="$WIZARDRY_TMPDIR/markers-here"
  mkdir -p "$destination" "$markers_dir"
  # Write resolved path to marker to match what jump will compare
  destination_resolved=$(cd "$destination" && pwd -P | sed 's|//|/|g')
  printf '%s\n' "$destination_resolved" >"$markers_dir/1"
  run_jump "1" "$markers_dir" "$destination"
  assert_success && assert_output_contains "already standing"
}

test_jump_changes_directory() {
  start_dir="$WIZARDRY_TMPDIR/start"
  destination="$WIZARDRY_TMPDIR/portal"
  markers_dir="$WIZARDRY_TMPDIR/markers-jump"
  mkdir -p "$start_dir" "$destination" "$markers_dir"
  # Write resolved path to marker
  destination_resolved=$(cd "$destination" && pwd -P | sed 's|//|/|g')
  printf '%s\n' "$destination_resolved" >"$markers_dir/1"
  run_jump "1" "$markers_dir" "$start_dir"
  assert_success
}

test_jump_to_named_marker() {
  start_dir="$WIZARDRY_TMPDIR/start-named"
  destination="$WIZARDRY_TMPDIR/portal-named"
  markers_dir="$WIZARDRY_TMPDIR/markers-named"
  mkdir -p "$start_dir" "$destination" "$markers_dir"
  destination_resolved=$(cd "$destination" && pwd -P | sed 's|//|/|g')
  printf '%s\n' "$destination_resolved" >"$markers_dir/alpha"
  run_jump "alpha" "$markers_dir" "$start_dir"
  assert_success
}

test_jump_lists_available_markers() {
  markers_dir="$WIZARDRY_TMPDIR/markers-list"
  dest="$WIZARDRY_TMPDIR/dest-list"
  mkdir -p "$markers_dir" "$dest"
  dest_resolved=$(cd "$dest" && pwd -P | sed 's|//|/|g')
  printf '%s\n' "$dest_resolved" >"$markers_dir/1"
  printf '%s\n' "$dest_resolved" >"$markers_dir/alpha"
  run_jump "nonexistent" "$markers_dir"
  assert_failure
  assert_output_contains "Available markers:"
  assert_output_contains "1"
  assert_output_contains "alpha"
}

test_jump_zero_cycles() {
  skip-if-compiled || return $?
  start_dir="$WIZARDRY_TMPDIR/start-zero"
  dest1="$WIZARDRY_TMPDIR/dest1"
  dest2="$WIZARDRY_TMPDIR/dest2"
  markers_dir="$WIZARDRY_TMPDIR/markers-zero"
  mkdir -p "$start_dir" "$dest1" "$dest2" "$markers_dir"
  dest1_resolved=$(cd "$dest1" && pwd -P | sed 's|//|/|g')
  dest2_resolved=$(cd "$dest2" && pwd -P | sed 's|//|/|g')
  # Create markers with different timestamps to ensure deterministic ls -t ordering
  printf '%s\n' "$dest1_resolved" >"$markers_dir/1"
  sleep 1
  printf '%s\n' "$dest2_resolved" >"$markers_dir/2"
  # jump 0 should cycle through markers
  run_jump "0" "$markers_dir" "$start_dir"
  assert_success
}

test_jump_next_cycles() {
  skip-if-compiled || return $?
  start_dir="$WIZARDRY_TMPDIR/start-next"
  dest1="$WIZARDRY_TMPDIR/dest-next-1"
  dest2="$WIZARDRY_TMPDIR/dest-next-2"
  markers_dir="$WIZARDRY_TMPDIR/markers-next"
  mkdir -p "$start_dir" "$dest1" "$dest2" "$markers_dir"
  dest1_resolved=$(cd "$dest1" && pwd -P | sed 's|//|/|g')
  dest2_resolved=$(cd "$dest2" && pwd -P | sed 's|//|/|g')
  printf '%s\n' "$dest1_resolved" >"$markers_dir/1"
  sleep 1
  printf '%s\n' "$dest2_resolved" >"$markers_dir/2"
  # jump next should cycle through markers
  run_jump "next" "$markers_dir" "$start_dir"
  assert_success
}

test_jump_defaults_to_one() {
  skip-if-compiled || return $?
  start_dir="$WIZARDRY_TMPDIR/start-default"
  dest1="$WIZARDRY_TMPDIR/dest-default-1"
  markers_dir="$WIZARDRY_TMPDIR/markers-default"
  mkdir -p "$start_dir" "$dest1" "$markers_dir"
  dest1_resolved=$(cd "$dest1" && pwd -P | sed 's|//|/|g')
  printf '%s\n' "$dest1_resolved" >"$markers_dir/1"
  # jump with no args should go to marker 1
  run_jump "" "$markers_dir" "$start_dir"
  assert_success
}

run_test_case "jump-to-marker prints usage" test_help
run_test_case "jump-to-marker rejects unknown options" test_unknown_option_fails
run_test_case "jump-to-marker fails when markers dir is missing" test_jump_requires_markers_dir
run_test_case "jump-to-marker fails when specific marker is missing" test_jump_requires_specific_marker
run_test_case "jump-to-marker fails when marker is blank" test_jump_rejects_blank_marker
run_test_case "jump-to-marker fails when destination is missing" test_jump_rejects_missing_destination
run_test_case "jump-to-marker reports when already at destination" test_jump_detects_current_location
run_test_case "jump-to-marker jumps to marked directory" test_jump_changes_directory
run_test_case "jump-to-marker jumps to named marker" test_jump_to_named_marker
run_test_case "jump-to-marker lists available markers on error" test_jump_lists_available_markers
run_test_case "jump 0 cycles through markers" test_jump_zero_cycles
run_test_case "jump next cycles through markers" test_jump_next_cycles
run_test_case "jump defaults to marker 1" test_jump_defaults_to_one
finish_tests
