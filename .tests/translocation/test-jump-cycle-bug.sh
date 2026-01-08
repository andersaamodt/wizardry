#!/bin/sh
# Test for the jump cycling bug reported in GitHub issue
# This test verifies that jump correctly cycles through markers
# and properly tracks the last-jumped marker via file mtime.

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

run_jump_sourced() {
  marker_arg=${1:-}
  markers_dir=${2:-$WIZARDRY_TMPDIR/markers}
  workdir=${3:-$WIZARDRY_TMPDIR}
  
  PATH="$WIZARDRY_IMPS_PATH:$(wizardry_base_path):/bin:/usr/bin"
  JUMP_TO_MARKERS_DIR="$markers_dir"
  export JUMP_TO_MARKERS_DIR PATH
  
  # Create a script that sources jump-to-marker in the same shell
  test_script="$WIZARDRY_TMPDIR/jump-test.sh"
  cat > "$test_script" << INNEREOF
#!/bin/sh
cd "$workdir" || exit 1
if [ -n "$marker_arg" ]; then
  set -- "$marker_arg"
else
  set --
fi
. "$ROOT_DIR/spells/translocation/jump-to-marker"
pwd -P | sed 's|//|/|g'
INNEREOF
  chmod +x "$test_script"
  
  run_cmd sh "$test_script"
}

# Test the reported bug scenario with 'next' keyword:
# 1. At .wizardry (marker 3)
# 2. Jump next should skip marker 3 (already there) and go to next marker
# 3. Repeated jump next should cycle through all markers without getting stuck
test_jump_cycle_after_explicit_jump() {
  skip-if-compiled || return $?
  
  tower="$WIZARDRY_TMPDIR/tower"
  wizardry_dir="$WIZARDRY_TMPDIR/wizardry"
  other_dir="$WIZARDRY_TMPDIR/other"
  markers_dir="$WIZARDRY_TMPDIR/markers-cycle"
  
  mkdir -p "$tower" "$wizardry_dir" "$other_dir" "$markers_dir"
  
  # Normalize paths
  tower_normalized=$(cd "$tower" && pwd -P | sed 's|//|/|g')
  wizardry_normalized=$(cd "$wizardry_dir" && pwd -P | sed 's|//|/|g')
  other_normalized=$(cd "$other_dir" && pwd -P | sed 's|//|/|g')
  
  # Create markers 1, 2, 3
  printf '%s\n' "$tower_normalized" > "$markers_dir/1"
  sleep 1  # Ensure different mtime
  printf '%s\n' "$wizardry_normalized" > "$markers_dir/2"
  sleep 1  # Ensure different mtime
  printf '%s\n' "$other_normalized" > "$markers_dir/3"
  sleep 1  # Ensure different mtime
  
  # Jump to marker 3 explicitly to set it as "most recent"
  run_jump_sourced "3" "$markers_dir" "$tower"
  assert_success || return 1
  assert_output_contains "$other_normalized" || return 1
  
  # Now at marker 3. Call "jump next" - should skip marker 3 and go to marker 1
  run_jump_sourced "next" "$markers_dir" "$other_dir"
  assert_success || return 1
  # Should NOT say "already standing"
  if printf '%s' "$OUTPUT" | grep -q "already standing"; then
    TEST_FAILURE_REASON="cycling should skip current location and jump to next marker"
    return 1
  fi
  # Should now be at marker 1 (tower)
  assert_output_contains "$tower_normalized" || return 1
  
  # Jump next again from tower - should go to marker 2
  run_jump_sourced "next" "$markers_dir" "$tower"
  assert_success || return 1
  if printf '%s' "$OUTPUT" | grep -q "already standing"; then
    TEST_FAILURE_REASON="cycling should jump to next marker, not stay at current location"
    return 1
  fi
  assert_output_contains "$wizardry_normalized" || return 1
}

# Test marker mtime tracking for cycling
test_marker_mtime_updated_on_jump() {
  skip-if-compiled || return $?
  
  dest1="$WIZARDRY_TMPDIR/dest1-mtime"
  dest2="$WIZARDRY_TMPDIR/dest2-mtime"
  markers_dir="$WIZARDRY_TMPDIR/markers-mtime"
  
  mkdir -p "$dest1" "$dest2" "$markers_dir"
  
  dest1_normalized=$(cd "$dest1" && pwd -P | sed 's|//|/|g')
  dest2_normalized=$(cd "$dest2" && pwd -P | sed 's|//|/|g')
  
  # Create markers with initial timestamps
  printf '%s\n' "$dest1_normalized" > "$markers_dir/1"
  sleep 1
  printf '%s\n' "$dest2_normalized" > "$markers_dir/2"
  sleep 1
  
  # Record initial mtime of marker 1
  marker1_mtime_before=$(stat -c %Y "$markers_dir/1" 2>/dev/null || stat -f %m "$markers_dir/1" 2>/dev/null)
  
  # Jump to marker 1
  run_jump_sourced "1" "$markers_dir" "$dest2"
  assert_success || return 1
  
  sleep 1
  
  # Check that marker 1's mtime was updated (touched)
  marker1_mtime_after=$(stat -c %Y "$markers_dir/1" 2>/dev/null || stat -f %m "$markers_dir/1" 2>/dev/null)
  
  if [ "$marker1_mtime_before" -ge "$marker1_mtime_after" ]; then
    TEST_FAILURE_REASON="marker file should be touched after successful jump"
    return 1
  fi
}

# Test that "already at marker" still touches the marker file for cycling
test_already_at_marker_updates_mtime() {
  skip-if-compiled || return $?
  
  dest="$WIZARDRY_TMPDIR/dest-already"
  markers_dir="$WIZARDRY_TMPDIR/markers-already"
  
  mkdir -p "$dest" "$markers_dir"
  
  dest_normalized=$(cd "$dest" && pwd -P | sed 's|//|/|g')
  
  printf '%s\n' "$dest_normalized" > "$markers_dir/1"
  sleep 1
  
  # Record initial mtime
  marker1_mtime_before=$(stat -c %Y "$markers_dir/1" 2>/dev/null || stat -f %m "$markers_dir/1" 2>/dev/null)
  
  # Jump to marker 1 when already at that location
  run_jump_sourced "1" "$markers_dir" "$dest"
  assert_success || return 1
  assert_output_contains "already standing" || return 1
  
  sleep 1
  
  # Check that marker was still touched even though we didn't actually move
  marker1_mtime_after=$(stat -c %Y "$markers_dir/1" 2>/dev/null || stat -f %m "$markers_dir/1" 2>/dev/null)
  
  if [ "$marker1_mtime_before" -ge "$marker1_mtime_after" ]; then
    TEST_FAILURE_REASON="marker file should be touched even when already at destination"
    return 1
  fi
}

run_test_case "jump next cycles and skips current marker" test_jump_cycle_after_explicit_jump
run_test_case "marker mtime is updated on successful jump" test_marker_mtime_updated_on_jump
run_test_case "already-at-marker still updates mtime for cycling" test_already_at_marker_updates_mtime

finish_tests
