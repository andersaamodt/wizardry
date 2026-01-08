#!/bin/sh
# Test that jump-to-marker correctly detects "already standing" even with symlinks
# This ensures both paths are resolved canonically via cd + pwd -P before comparison

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

# Test: Mark via symlink, jump when at real path
test_detects_already_at_real_path_when_marked_via_symlink() {
  skip-if-compiled || return $?
  
  real_dir="$WIZARDRY_TMPDIR/real-destination"
  link_dir="$WIZARDRY_TMPDIR/link-destination"
  markers_dir="$WIZARDRY_TMPDIR/markers-symlink"
  
  mkdir -p "$real_dir" "$markers_dir"
  ln -s "$real_dir" "$link_dir"
  
  # Normalize real path
  real_normalized=$(cd "$real_dir" && pwd -P | sed 's|//|/|g')
  
  # Mark the location via the symlink (link resolves to real via pwd -P)
  link_normalized=$(cd "$link_dir" && pwd -P | sed 's|//|/|g')
  printf '%s\n' "$link_normalized" > "$markers_dir/1"
  
  # Jump from the real path (should detect we're already there)
  run_jump_sourced "1" "$markers_dir" "$real_dir"
  assert_success || return 1
  assert_output_contains "already standing" || return 1
}

# Test: Mark via real path, jump when at symlink path
test_detects_already_at_symlink_when_marked_via_real() {
  skip-if-compiled || return $?
  
  real_dir="$WIZARDRY_TMPDIR/real-destination2"
  link_dir="$WIZARDRY_TMPDIR/link-destination2"
  markers_dir="$WIZARDRY_TMPDIR/markers-symlink2"
  
  mkdir -p "$real_dir" "$markers_dir"
  ln -s "$real_dir" "$link_dir"
  
  # Normalize paths
  real_normalized=$(cd "$real_dir" && pwd -P | sed 's|//|/|g')
  link_normalized=$(cd "$link_dir" && pwd -P | sed 's|//|/|g')
  
  # Mark the location via the real path
  printf '%s\n' "$real_normalized" > "$markers_dir/1"
  
  # Jump from the symlink path (should detect we're already there)
  run_jump_sourced "1" "$markers_dir" "$link_dir"
  assert_success || return 1
  assert_output_contains "already standing" || return 1
}

# Test: Multiple jumps to same marker via different paths all detect "already standing"
test_repeated_jumps_via_different_paths() {
  skip-if-compiled || return $?
  
  real_dir="$WIZARDRY_TMPDIR/real-destination3"
  link_dir="$WIZARDRY_TMPDIR/link-destination3"
  markers_dir="$WIZARDRY_TMPDIR/markers-symlink3"
  
  mkdir -p "$real_dir" "$markers_dir"
  ln -s "$real_dir" "$link_dir"
  
  real_normalized=$(cd "$real_dir" && pwd -P | sed 's|//|/|g')
  
  # Mark via real path
  printf '%s\n' "$real_normalized" > "$markers_dir/1"
  
  # First jump from elsewhere - should succeed
  run_jump_sourced "1" "$markers_dir" "$WIZARDRY_TMPDIR"
  assert_success || return 1
  if printf '%s' "$OUTPUT" | grep -q "already standing"; then
    TEST_FAILURE_REASON="first jump should not say 'already standing'"
    return 1
  fi
  
  # Second jump from real path - should say already standing
  run_jump_sourced "1" "$markers_dir" "$real_dir"
  assert_success || return 1
  assert_output_contains "already standing" || return 1
  
  # Third jump from symlink path - should also say already standing
  run_jump_sourced "1" "$markers_dir" "$link_dir"
  assert_success || return 1
  assert_output_contains "already standing" || return 1
}

run_test_case "detects already-at when marked via symlink, at real path" test_detects_already_at_real_path_when_marked_via_symlink
run_test_case "detects already-at when marked via real path, at symlink" test_detects_already_at_symlink_when_marked_via_real
run_test_case "repeated jumps via different paths detect already-at" test_repeated_jumps_via_different_paths

finish_tests
