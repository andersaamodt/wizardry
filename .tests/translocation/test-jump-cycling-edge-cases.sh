#!/bin/sh
# Test edge cases for jump next and jump 0 cycling

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_jump_next_no_markers() {
  tmpdir=$(make_tempdir)
  markers_dir="$tmpdir/markers"
  mkdir -p "$markers_dir"
  
  # Test jump next with empty markers directory
  run_cmd sh -c "
    export JUMP_TO_MARKERS_DIR='$markers_dir'
    export PATH='$ROOT_DIR/spells/.imps:$ROOT_DIR/spells/.imps/sys:/bin:/usr/bin'
    cd '$tmpdir'
    set -- next
    . '$ROOT_DIR/spells/translocation/jump-to-marker'
  "
  
  assert_failure || return 1
  assert_error_contains "No markers available to cycle through" || return 1
}

test_jump_zero_no_markers() {
  tmpdir=$(make_tempdir)
  markers_dir="$tmpdir/markers"
  mkdir -p "$markers_dir"
  
  # Test jump 0 with empty markers directory
  run_cmd sh -c "
    export JUMP_TO_MARKERS_DIR='$markers_dir'
    export PATH='$ROOT_DIR/spells/.imps:$ROOT_DIR/spells/.imps/sys:/bin:/usr/bin'
    cd '$tmpdir'
    set -- 0
    . '$ROOT_DIR/spells/translocation/jump-to-marker'
  "
  
  assert_failure || return 1
  assert_error_contains "No markers available to cycle through" || return 1
}

run_test_case "jump next with no markers shows helpful error" test_jump_next_no_markers
run_test_case "jump 0 with no markers shows helpful error" test_jump_zero_no_markers
finish_tests
