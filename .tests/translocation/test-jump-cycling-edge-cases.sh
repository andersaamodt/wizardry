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

test_jump_next_with_markers() {
  tmpdir=$(make_tempdir)
  markers_dir="$tmpdir/markers"
  mkdir -p "$markers_dir"
  
  # Create 3 marker directories
  mkdir -p "$tmpdir/loc1" "$tmpdir/loc2" "$tmpdir/loc3"
  printf '%s\n' "$tmpdir/loc1" > "$markers_dir/1"
  printf '%s\n' "$tmpdir/loc2" > "$markers_dir/2"
  printf '%s\n' "$tmpdir/loc3" > "$markers_dir/3"
  
  # Touch marker 1 to make it most recent
  sleep 0.1
  touch "$markers_dir/1"
  
  # Test jump next should go to marker 2 (next after 1)
  run_cmd sh -c "
    export JUMP_TO_MARKERS_DIR='$markers_dir'
    export PATH='$ROOT_DIR/spells/.imps:$ROOT_DIR/spells/.imps/sys:/bin:/usr/bin'
    cd '$tmpdir'
    set -- next
    . '$ROOT_DIR/spells/translocation/jump-to-marker'
    pwd -P
  "
  
  assert_success || return 1
  # Should have changed to loc2
  assert_output_contains "loc2" || return 1
}

test_jump_zero_with_markers() {
  tmpdir=$(make_tempdir)
  markers_dir="$tmpdir/markers"
  mkdir -p "$markers_dir"
  
  # Create 3 marker directories
  mkdir -p "$tmpdir/loc1" "$tmpdir/loc2" "$tmpdir/loc3"
  printf '%s\n' "$tmpdir/loc1" > "$markers_dir/1"
  printf '%s\n' "$tmpdir/loc2" > "$markers_dir/2"
  printf '%s\n' "$tmpdir/loc3" > "$markers_dir/3"
  
  # Touch marker 2 to make it most recent
  sleep 0.1
  touch "$markers_dir/2"
  
  # Test jump 0 should go to marker 3 (next after 2)
  run_cmd sh -c "
    export JUMP_TO_MARKERS_DIR='$markers_dir'
    export PATH='$ROOT_DIR/spells/.imps:$ROOT_DIR/spells/.imps/sys:/bin:/usr/bin'
    cd '$tmpdir'
    set -- 0
    . '$ROOT_DIR/spells/translocation/jump-to-marker'
    pwd -P
  "
  
  assert_success || return 1
  # Should have changed to loc3
  assert_output_contains "loc3" || return 1
}

run_test_case "jump next with no markers shows helpful error" test_jump_next_no_markers
run_test_case "jump 0 with no markers shows helpful error" test_jump_zero_no_markers
run_test_case "jump next with markers cycles correctly" test_jump_next_with_markers
run_test_case "jump 0 with markers cycles correctly" test_jump_zero_with_markers
finish_tests
