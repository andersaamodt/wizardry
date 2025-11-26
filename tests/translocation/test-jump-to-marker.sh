#!/bin/sh
# Behavioral cases (derived from --help):
# - jump-to-marker prints usage

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/translocation/jump-to-marker" --help
  assert_success && assert_output_contains "Usage: jump-to-marker"
}

test_unknown_option_fails() {
  run_spell "spells/translocation/jump-to-marker" --bad
  assert_failure && assert_error_contains "unknown option"
}

test_install_requires_helpers() {
  helpers_dir="$WIZARDRY_TMPDIR/helpers-missing"
  mkdir -p "$helpers_dir"
  PATH="/bin:/usr/bin" JUMP_TO_MARKER_HELPERS_DIR="$helpers_dir" MARKER_FILE="$WIZARDRY_TMPDIR/marker" \
    run_spell "spells/translocation/jump-to-marker" --install
  assert_failure && assert_error_contains "required helper 'detect-rc-file' is missing"
}

run_jump() {
  marker=$1
  RUN_CMD_WORKDIR=${2:-$WIZARDRY_TMPDIR}
  PATH="/bin:/usr/bin"
  JUMP_TO_MARKER_FILE="$marker"
  export JUMP_TO_MARKER_FILE PATH
  run_cmd sh -c ". \"$ROOT_DIR/spells/translocation/jump-to-marker\"; jump"
}

test_jump_requires_marker_file() {
  missing_marker="$WIZARDRY_TMPDIR/no-marker"
  run_jump "$missing_marker"
  assert_failure && assert_output_contains "No location has been marked"
}

test_jump_rejects_blank_marker() {
  blank_marker="$WIZARDRY_TMPDIR/blank-marker"
  : >"$blank_marker"
  run_jump "$blank_marker"
  assert_failure && assert_output_contains "rune is blank"
}

test_jump_rejects_missing_destination() {
  missing_target="$WIZARDRY_TMPDIR/missing-destination"
  printf '%s\n' "$missing_target" >"$WIZARDRY_TMPDIR/marker"
  run_jump "$WIZARDRY_TMPDIR/marker"
  assert_failure && assert_output_contains "no longer exists"
}

test_jump_detects_current_location() {
  destination="$WIZARDRY_TMPDIR/already-here"
  mkdir -p "$destination"
  # Write resolved path to marker to match what jump will compare
  destination_resolved=$(cd "$destination" && pwd -P | sed 's|//|/|g')
  printf '%s\n' "$destination_resolved" >"$WIZARDRY_TMPDIR/marker"
  run_jump "$WIZARDRY_TMPDIR/marker" "$destination"
  assert_success && assert_output_contains "already standing"
}

test_jump_changes_directory() {
  start_dir="$WIZARDRY_TMPDIR/start"
  destination="$WIZARDRY_TMPDIR/portal"
  mkdir -p "$start_dir" "$destination"
  # Write resolved path to marker and expect it in output
  destination_resolved=$(cd "$destination" && pwd -P | sed 's|//|/|g')
  printf '%s\n' "$destination_resolved" >"$WIZARDRY_TMPDIR/marker"
  run_jump "$WIZARDRY_TMPDIR/marker" "$start_dir"
  assert_success && assert_output_contains "You land in $destination_resolved"
}

run_test_case "jump-to-marker prints usage" test_help
run_test_case "jump-to-marker rejects unknown options" test_unknown_option_fails
run_test_case "jump-to-marker install fails when helpers missing" test_install_requires_helpers
run_test_case "jump-to-marker fails when marker is missing" test_jump_requires_marker_file
run_test_case "jump-to-marker fails when marker is blank" test_jump_rejects_blank_marker
run_test_case "jump-to-marker fails when destination is missing" test_jump_rejects_missing_destination
run_test_case "jump-to-marker reports when already at destination" test_jump_detects_current_location
run_test_case "jump-to-marker jumps to marked directory" test_jump_changes_directory
finish_tests
