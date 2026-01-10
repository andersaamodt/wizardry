#!/bin/sh

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
  run_spell "spells/translocation/random-blink" --help
  assert_success && assert_output_contains "Usage:"
}

test_blink_with_subdirs() {
  tmpdir=$(make_tempdir)
  start_dir="$tmpdir/start"
  mkdir -p "$start_dir"
  
  # Create a tree of subdirectories in start_dir
  mkdir -p "$start_dir/dir1"
  mkdir -p "$start_dir/dir2"
  mkdir -p "$start_dir/dir3"
  mkdir -p "$start_dir/dir1/subdir1"
  mkdir -p "$start_dir/dir1/subdir2"
  
  start_normalized=$(cd "$start_dir" && pwd -P | sed 's|//|/|g')
  
  # Run random-blink from start_dir
  PATH="$WIZARDRY_IMPS_PATH:$(wizardry_base_path):/bin:/usr/bin"
  RUN_CMD_WORKDIR="$start_dir"
  export PATH RUN_CMD_WORKDIR
  run_cmd sh -c ". \"$ROOT_DIR/spells/translocation/random-blink\"; pwd -P | sed 's|//|/|g'"
  
  assert_success || return 1
  
  # Verify we moved to a subdirectory
  # The output may include the arrival message, so get the last line (the pwd output)
  new_pwd=$(printf '%s' "$OUTPUT" | tail -n 1)
  
  # We should be in a different directory than where we started
  [ "$new_pwd" != "$start_normalized" ] || {
    printf 'Expected to move to a subdirectory, but stayed in: %s\n' "$new_pwd" >&2
    return 1
  }
  
  # We should be within the temp directory tree
  case "$new_pwd" in
    "$start_normalized"/*)
      # Good - we're in a subdirectory
      ;;
    *)
      printf 'Ended up outside the start directory: %s (expected under %s)\n' "$new_pwd" "$start_normalized" >&2
      return 1
      ;;
  esac
}

test_blink_no_subdirs() {
  tmpdir=$(make_tempdir)
  
  PATH="$WIZARDRY_IMPS_PATH:$(wizardry_base_path):/bin:/usr/bin"
  RUN_CMD_WORKDIR="$tmpdir"
  export PATH RUN_CMD_WORKDIR
  run_cmd sh -c ". \"$ROOT_DIR/spells/translocation/random-blink\""
  
  assert_failure || return 1
  assert_output_contains "No subdirectories found"
}

test_blink_depth_limit() {
  tmpdir=$(make_tempdir)
  start_dir="$tmpdir/start"
  mkdir -p "$start_dir"
  
  # Create nested directories (only direct child)
  mkdir -p "$start_dir/a/b/c/d/e"
  
  start_normalized=$(cd "$start_dir" && pwd -P | sed 's|//|/|g')
  
  # Run random-blink with depth limit of 1
  PATH="$WIZARDRY_IMPS_PATH:$(wizardry_base_path):/bin:/usr/bin"
  RUN_CMD_WORKDIR="$start_dir"
  export PATH RUN_CMD_WORKDIR
  run_cmd sh -c "set -- 1; . \"$ROOT_DIR/spells/translocation/random-blink\"; pwd -P | sed 's|//|/|g'"
  
  assert_success || return 1
  
  # Should be in a direct subdirectory only
  # The output may include the arrival message, so get the last line (the pwd output)
  new_pwd=$(printf '%s' "$OUTPUT" | tail -n 1)
  
  # Count the depth - should be exactly 1 level deeper
  relative_path=$(printf '%s' "$new_pwd" | sed "s|^$start_normalized||")
  depth=$(printf '%s' "$relative_path" | grep -o '/' | grep -c '^' || echo 0)
  
  [ "$depth" -eq 1 ] || {
    printf 'Expected depth 1, got depth %s (pwd: %s, relative: %s)\n' "$depth" "$new_pwd" "$relative_path" >&2
    return 1
  }
}

test_blink_multiple_attempts() {
  tmpdir=$(make_tempdir)
  start_dir="$tmpdir/start"
  mkdir -p "$start_dir"
  
  # Create multiple subdirectories
  mkdir -p "$start_dir/dir1"
  mkdir -p "$start_dir/dir2"
  mkdir -p "$start_dir/dir3"
  mkdir -p "$start_dir/dir4"
  mkdir -p "$start_dir/dir5"
  
  # Try random-blink 50 times to ensure it works consistently (as mentioned in problem statement)
  success_count=0
  attempt=0
  while [ "$attempt" -lt 50 ]; do
    attempt=$((attempt + 1))
    
    # Run random-blink from start_dir
    PATH="$WIZARDRY_IMPS_PATH:$(wizardry_base_path):/bin:/usr/bin"
    RUN_CMD_WORKDIR="$start_dir"
    export PATH RUN_CMD_WORKDIR
    run_cmd sh -c ". \"$ROOT_DIR/spells/translocation/random-blink\" 2>/dev/null"
    
    if [ "$STATUS" -eq 0 ]; then
      success_count=$((success_count + 1))
    fi
  done
  
  # All 50 attempts should succeed (as mentioned in problem statement)
  [ "$success_count" -eq 50 ] || {
    printf 'Expected 50 successful random-blinks, got %s\n' "$success_count" >&2
    return 1
  }
}

test_blink_invalid_depth() {
  tmpdir=$(make_tempdir)
  
  PATH="$WIZARDRY_IMPS_PATH:$(wizardry_base_path):/bin:/usr/bin"
  RUN_CMD_WORKDIR="$tmpdir"
  export PATH RUN_CMD_WORKDIR
  
  run_cmd sh -c "set -- 0; . \"$ROOT_DIR/spells/translocation/random-blink\""
  assert_failure && assert_error_contains "must be between 1 and 10"
  
  run_cmd sh -c "set -- 11; . \"$ROOT_DIR/spells/translocation/random-blink\""
  assert_failure && assert_error_contains "must be between 1 and 10"
  
  run_cmd sh -c "set -- abc; . \"$ROOT_DIR/spells/translocation/random-blink\""
  assert_failure && assert_error_contains "must be a number"
}

run_test_case "random-blink prints usage" test_help
run_test_case "random-blink moves to subdirectory" test_blink_with_subdirs
run_test_case "random-blink fails when no subdirectories" test_blink_no_subdirs
run_test_case "random-blink respects depth limit" test_blink_depth_limit
run_test_case "random-blink works consistently (50 attempts)" test_blink_multiple_attempts
run_test_case "random-blink validates depth parameter" test_blink_invalid_depth

finish_tests
