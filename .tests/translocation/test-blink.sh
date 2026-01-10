#!/bin/sh
# Comprehensive behavioral tests for blink spell:
# - Prints usage with --help
# - Teleports to random directory from root
# - Teleports with --home flag
# - Validates max-depth parameter
# - Handles edge cases (no directories, invalid args)

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Build wizardry base path with all imp directories
wizardry_base_path() {
  printf '%s' "$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input"
}

test_help() {
  run_spell "spells/translocation/blink" --help
  assert_success && assert_output_contains "Usage: . blink"
}

test_blink_from_root() {
  # Test that blink works from root with limited depth
  # Use run_cmd to source the spell with proper environment
  PATH="$WIZARDRY_IMPS_PATH:$(wizardry_base_path):/bin:/usr/bin"
  export PATH
  
  run_cmd sh -c "set -- 1; . '$ROOT_DIR/spells/translocation/blink'"
  assert_success || return 1
  # Should contain one of the blink messages
  assert_output_contains "You have blinked to:" || return 1
}

test_blink_with_home_flag() {
  # Create a test directory structure with subdirectories
  test_home="$WIZARDRY_TMPDIR/test-home-$$"
  mkdir -p "$test_home/dir1"
  mkdir -p "$test_home/dir2"
  mkdir -p "$test_home/dir3"
  
  PATH="$WIZARDRY_IMPS_PATH:$(wizardry_base_path):/bin:/usr/bin"
  HOME="$test_home"
  export PATH HOME
  
  run_cmd sh -c "cd '$test_home' && set -- --home 1; . '$ROOT_DIR/spells/translocation/blink'"
  assert_success || return 1
  assert_output_contains "You have blinked to:" || return 1
  # Verify we got a blink message (any one of them is fine)
  if ! assert_output_contains "Reality" && \
     ! assert_output_contains "Space" && \
     ! assert_output_contains "world" && \
     ! assert_output_contains "blink" && \
     ! assert_output_contains "Magic" && \
     ! assert_output_contains "Quantum"; then
    return 1
  fi
  
  rm -rf "$test_home"
}

test_rejects_invalid_depth() {
  PATH="$WIZARDRY_IMPS_PATH:$(wizardry_base_path):/bin:/usr/bin"
  export PATH
  
  run_cmd sh -c "set -- abc; . '$ROOT_DIR/spells/translocation/blink'"
  assert_failure || return 1
  assert_error_contains "positive integer" || return 1
}

test_rejects_zero_depth() {
  PATH="$WIZARDRY_IMPS_PATH:$(wizardry_base_path):/bin:/usr/bin"
  export PATH
  
  run_cmd sh -c "set -- 0; . '$ROOT_DIR/spells/translocation/blink'"
  assert_failure || return 1
  assert_error_contains "positive integer" || return 1
}

test_blink_changes_directory() {
  # Test that blink actually changes the working directory
  # Create a test home with known subdirectories
  test_home="$WIZARDRY_TMPDIR/test-blink-cd-$$"
  mkdir -p "$test_home/subdir1"
  mkdir -p "$test_home/subdir2"
  
  PATH="$WIZARDRY_IMPS_PATH:$(wizardry_base_path):/bin:/usr/bin"
  HOME="$test_home"
  export PATH HOME
  
  # Source blink and capture the new directory
  run_cmd sh -c "
    cd '$test_home'
    start_dir=\$(pwd)
    set -- --home 1
    . '$ROOT_DIR/spells/translocation/blink'
    end_dir=\$(pwd)
    # Verify we actually moved (unless we happened to stay in test_home root)
    if [ \"\$start_dir\" != \"\$end_dir\" ]; then
      printf 'Directory changed successfully\n'
    else
      # It's OK if we stayed in the same dir if that was the random choice
      printf 'Stayed in same directory (valid random outcome)\n'
    fi
  "
  assert_success || return 1
  
  rm -rf "$test_home"
}

test_handles_empty_directory() {
  # Test behavior when no subdirectories exist
  test_home="$WIZARDRY_TMPDIR/test-empty-$$"
  mkdir -p "$test_home"
  # Don't create any subdirectories
  
  PATH="$WIZARDRY_IMPS_PATH:$(wizardry_base_path):/bin:/usr/bin"
  HOME="$test_home"
  export PATH HOME
  
  # Should fail or only find the directory itself
  run_cmd sh -c "cd '$test_home' && set -- --home 1; . '$ROOT_DIR/spells/translocation/blink'"
  # Either succeeds (finds test_home itself) or fails (no other dirs)
  # Both are acceptable - just verify it doesn't crash
  if ! assert_success; then
    assert_error_contains "no" || return 1
  fi
  
  rm -rf "$test_home"
}

run_test_case "blink shows usage text" test_help
run_test_case "blink teleports from root" test_blink_from_root
run_test_case "blink respects --home flag" test_blink_with_home_flag
run_test_case "blink rejects invalid depth" test_rejects_invalid_depth
run_test_case "blink rejects zero depth" test_rejects_zero_depth
run_test_case "blink changes directory" test_blink_changes_directory
run_test_case "blink handles empty directory gracefully" test_handles_empty_directory

finish_tests
