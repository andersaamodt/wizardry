#!/bin/sh
# Tests for the 'script-dir' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_script_dir_returns_absolute_path() {
  skip-if-compiled || return $?
  run_spell spells/.imps/paths/script-dir spells/.imps/paths/script-dir
  assert_success || return 1
  # Should output an absolute path
  case "$OUTPUT" in
    /*) return 0 ;;
    *) TEST_FAILURE_REASON="should output absolute path, got: $OUTPUT"; return 1 ;;
  esac
}

test_script_dir_returns_correct_directory() {
  skip-if-compiled || return $?
  run_spell spells/.imps/paths/script-dir spells/.imps/paths/script-dir
  assert_success || return 1
  # Output should end with /spells/.imps/paths
  case "$OUTPUT" in
    */spells/.imps/paths) return 0 ;;
    *) TEST_FAILURE_REASON="should output paths directory, got: $OUTPUT"; return 1 ;;
  esac
}

test_script_dir_normalized_path() {
  run_spell spells/.imps/paths/script-dir spells/.imps/paths/script-dir
  assert_success || return 1
  # Output should not contain multiple consecutive slashes
  case "$OUTPUT" in
    *///*) TEST_FAILURE_REASON="path should be normalized, got: $OUTPUT"; return 1 ;;
    *) return 0 ;;
  esac
}

test_script_dir_handles_simple_name() {
  skip-if-compiled || return $?
  # When given just a filename without path separators
  tmpdir=$(make_tempdir)
  cp "$ROOT_DIR/spells/.imps/paths/script-dir" "$tmpdir/script-dir"
  chmod +x "$tmpdir/script-dir"
  
  # Run from the temp directory with just the filename
  output=$(cd "$tmpdir" && sh ./script-dir script-dir 2>&1) || true
  
  # Should return the tmpdir (resolve through pwd -P for macOS /var -> /private/var)
  # shellcheck disable=SC1007
  norm_tmpdir=$( (CDPATH= cd -- "$tmpdir" && pwd -P) | sed 's|//|/|g')
  case "$output" in
    "$norm_tmpdir") return 0 ;;
    *) TEST_FAILURE_REASON="expected $norm_tmpdir, got: $output"; return 1 ;;
  esac
}

test_script_dir_handles_symlink() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/actual"
  mkdir -p "$tmpdir/link_dir"
  
  # Create the actual script
  cp "$ROOT_DIR/spells/.imps/paths/script-dir" "$tmpdir/actual/script-dir"
  chmod +x "$tmpdir/actual/script-dir"
  
  # Create a symlink to the script (named script-dir so self-exec matches)
  ln -s "$tmpdir/actual/script-dir" "$tmpdir/link_dir/script-dir"
  
  # Run through the symlink
  output=$(sh "$tmpdir/link_dir/script-dir" "$tmpdir/link_dir/script-dir" 2>&1) || true
  
  # Should resolve to the actual directory, not the symlink directory
  # Resolve through pwd -P for macOS /var -> /private/var
  # shellcheck disable=SC1007
  norm_actual=$( (CDPATH= cd -- "$tmpdir/actual" && pwd -P) | sed 's|//|/|g')
  case "$output" in
    "$norm_actual") return 0 ;;
    *) TEST_FAILURE_REASON="expected $norm_actual (actual dir), got: $output"; return 1 ;;
  esac
}

test_script_dir_handles_relative_path() {
  skip-if-compiled || return $?
  # Create a temp script and run with a relative path
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/sub/dir"
  cp "$ROOT_DIR/spells/.imps/paths/script-dir" "$tmpdir/sub/dir/script-dir"
  chmod +x "$tmpdir/sub/dir/script-dir"
  
  # Run from tmpdir with relative path
  output=$(cd "$tmpdir" && sh sub/dir/script-dir sub/dir/script-dir 2>&1) || true
  
  # Resolve through pwd -P for macOS /var -> /private/var
  # shellcheck disable=SC1007
  norm_expected=$( (CDPATH= cd -- "$tmpdir/sub/dir" && pwd -P) | sed 's|//|/|g')
  case "$output" in
    "$norm_expected") return 0 ;;
    *) TEST_FAILURE_REASON="expected $norm_expected, got: $output"; return 1 ;;
  esac
}

test_script_dir_handles_dot_slash() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  cp "$ROOT_DIR/spells/.imps/paths/script-dir" "$tmpdir/script-dir"
  chmod +x "$tmpdir/script-dir"
  
  # Run with ./script-dir syntax
  output=$(cd "$tmpdir" && sh ./script-dir ./script-dir 2>&1) || true
  
  # Resolve through pwd -P for macOS /var -> /private/var
  # shellcheck disable=SC1007
  norm_tmpdir=$( (CDPATH= cd -- "$tmpdir" && pwd -P) | sed 's|//|/|g')
  case "$output" in
    "$norm_tmpdir") return 0 ;;
    *) TEST_FAILURE_REASON="expected $norm_tmpdir, got: $output"; return 1 ;;
  esac
}

test_script_dir_handles_relative_symlink() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/actual"
  mkdir -p "$tmpdir/links"
  
  # Create the actual script
  cp "$ROOT_DIR/spells/.imps/paths/script-dir" "$tmpdir/actual/script-dir"
  chmod +x "$tmpdir/actual/script-dir"
  
  # Create a relative symlink (not absolute) - named script-dir so self-exec matches
  ln -s ../actual/script-dir "$tmpdir/links/script-dir"
  
  # Run through the symlink
  output=$(sh "$tmpdir/links/script-dir" "$tmpdir/links/script-dir" 2>&1) || true
  
  # Should resolve to the actual directory
  # Resolve through pwd -P for macOS /var -> /private/var
  # shellcheck disable=SC1007
  norm_actual=$( (CDPATH= cd -- "$tmpdir/actual" && pwd -P) | sed 's|//|/|g')
  case "$output" in
    "$norm_actual") return 0 ;;
    *) TEST_FAILURE_REASON="expected $norm_actual (actual dir), got: $output"; return 1 ;;
  esac
}

test_script_dir_handles_same_dir_symlink() {
  skip-if-compiled || return $?
  # Edge case: symlink points to a file in the same directory
  tmpdir=$(make_tempdir)
  
  # Create the actual script
  cp "$ROOT_DIR/spells/.imps/paths/script-dir" "$tmpdir/real-script-dir"
  chmod +x "$tmpdir/real-script-dir"
  
  # Create a symlink in the same directory (target has no path separator)
  ln -s real-script-dir "$tmpdir/script-dir"
  
  # Run through the symlink
  output=$(sh "$tmpdir/script-dir" "$tmpdir/script-dir" 2>&1) || true
  
  # Should return the same directory
  # Resolve through pwd -P for macOS /var -> /private/var
  # shellcheck disable=SC1007
  norm_tmpdir=$( (CDPATH= cd -- "$tmpdir" && pwd -P) | sed 's|//|/|g')
  case "$output" in
    "$norm_tmpdir") return 0 ;;
    *) TEST_FAILURE_REASON="expected $norm_tmpdir, got: $output"; return 1 ;;
  esac
}

run_test_case "script-dir returns absolute path" test_script_dir_returns_absolute_path
run_test_case "script-dir returns correct directory" test_script_dir_returns_correct_directory
run_test_case "script-dir returns normalized path" test_script_dir_normalized_path
run_test_case "script-dir handles simple name" test_script_dir_handles_simple_name
run_test_case "script-dir handles symlinks" test_script_dir_handles_symlink
run_test_case "script-dir handles relative paths" test_script_dir_handles_relative_path
run_test_case "script-dir handles ./script syntax" test_script_dir_handles_dot_slash
run_test_case "script-dir handles relative symlinks" test_script_dir_handles_relative_symlink
run_test_case "script-dir handles same-dir symlinks" test_script_dir_handles_same_dir_symlink

finish_tests
