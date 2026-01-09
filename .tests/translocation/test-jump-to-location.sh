#!/bin/sh
# Test jump-to-location spell (synonym for jump-to-marker)

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
  run_spell "spells/translocation/jump-to-location" --help
  assert_success && assert_output_contains "Usage:"
}

test_jump_to_location_works() {
  skip-if-compiled || return $?
  markers_dir=$WIZARDRY_TMPDIR/markers
  mkdir -p "$markers_dir"
  start_dir=$WIZARDRY_TMPDIR/start
  mkdir -p "$start_dir"
  dest=$WIZARDRY_TMPDIR/dest
  mkdir -p "$dest"
  dest_resolved=$(cd "$dest" && pwd -P | sed 's|//|/|g')
  printf '%s\n' "$dest_resolved" >"$markers_dir/1"
  
  RUN_CMD_WORKDIR="$start_dir"
  PATH="$WIZARDRY_IMPS_PATH:$(wizardry_base_path):/bin:/usr/bin"
  JUMP_TO_MARKERS_DIR="$markers_dir"
  export JUMP_TO_MARKERS_DIR PATH RUN_CMD_WORKDIR
  
  run_cmd sh -c '. "$ROOT_DIR/spells/translocation/jump-to-location"'
  assert_success
}

run_test_case "jump-to-location prints usage" test_help
run_test_case "jump-to-location works as synonym" test_jump_to_location_works
finish_tests
