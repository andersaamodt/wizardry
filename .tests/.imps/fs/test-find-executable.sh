#!/bin/sh
# Test find-executable imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_find_executable_finds_files() {
  # Create temp dir with executable and non-executable files
  tmpdir=$(make_tempdir)
  
  # Create executable file
  cat > "$tmpdir/executable.sh" << 'EOF'
#!/bin/sh
echo "test"
EOF
  chmod +x "$tmpdir/executable.sh"
  
  # Create non-executable file
  cat > "$tmpdir/not-executable.txt" << 'EOF'
Just text
EOF
  chmod -x "$tmpdir/not-executable.txt"
  
  # Run find-executable
  run_spell "spells/.imps/fs/find-executable" "$tmpdir"
  assert_success || return 1
  assert_output_contains "executable.sh" || return 1
  
  # Should NOT contain non-executable file
  if printf '%s' "$OUTPUT" | grep -q "not-executable.txt"; then
    fail "find-executable should not find non-executable files"
    return 1
  fi
}

test_find_executable_works_recursively() {
  # Create temp dir with nested structure
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/subdir"
  
  # Create executable in subdir
  cat > "$tmpdir/subdir/nested.sh" << 'EOF'
#!/bin/sh
echo "nested"
EOF
  chmod +x "$tmpdir/subdir/nested.sh"
  
  # Run find-executable
  run_spell "spells/.imps/fs/find-executable" "$tmpdir"
  assert_success || return 1
  assert_output_contains "nested.sh" || return 1
}

test_find_executable_handles_missing_dir() {
  # Test with non-existent directory
  run_spell "spells/.imps/fs/find-executable" "/nonexistent/path/12345"
  assert_failure || return 1
  assert_error_contains "directory not found" || return 1
}

test_find_executable_handles_empty_dir() {
  # Test with empty directory
  tmpdir=$(make_tempdir)
  
  run_spell "spells/.imps/fs/find-executable" "$tmpdir"
  assert_success || return 1
  
  # Output should be empty
  if [ -n "$OUTPUT" ]; then
    fail "find-executable should produce no output for empty directory"
    return 1
  fi
}

test_find_executable_uses_current_dir() {
  # Test default to current directory
  tmpdir=$(make_tempdir)
  cd "$tmpdir" || return 1
  
  # Create executable in current dir
  cat > "current.sh" << 'EOF'
#!/bin/sh
echo "current"
EOF
  chmod +x "current.sh"
  
  # Run without argument (should use current dir)
  run_spell "spells/.imps/fs/find-executable"
  assert_success || return 1
  assert_output_contains "current.sh" || return 1
}

run_test_case "find-executable finds executable files" test_find_executable_finds_files
run_test_case "find-executable works recursively" test_find_executable_works_recursively
run_test_case "find-executable handles missing directory" test_find_executable_handles_missing_dir
run_test_case "find-executable handles empty directory" test_find_executable_handles_empty_dir
run_test_case "find-executable defaults to current directory" test_find_executable_uses_current_dir

finish_tests
