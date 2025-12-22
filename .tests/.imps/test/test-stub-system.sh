#!/bin/sh
# Test the stub system itself to verify every component works

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Test 1: Verify stub files exist and are executable
test_stub_files_exist() {
  missing=""
  for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty await-keypress; do
    stub_path="$ROOT_DIR/spells/.imps/test/stub-$stub"
    if [ ! -f "$stub_path" ]; then
      missing="${missing}${missing:+, }stub-$stub (missing)"
    elif [ ! -x "$stub_path" ]; then
      missing="${missing}${missing:+, }stub-$stub (not executable)"
    fi
  done
  
  if [ -n "$missing" ]; then
    TEST_FAILURE_REASON="stub files issues: $missing"
    return 1
  fi
  return 0
}

# Test 2: Verify stubs can be executed directly
test_stubs_execute_directly() {
  # Test fathom-cursor
  output=$("$ROOT_DIR/spells/.imps/test/stub-fathom-cursor" 2>&1)
  [ "$output" = "1 1" ] || {
    TEST_FAILURE_REASON="stub-fathom-cursor failed: expected '1 1', got '$output'"
    return 1
  }
  
  # Test fathom-cursor with -x flag
  output=$("$ROOT_DIR/spells/.imps/test/stub-fathom-cursor" -x 2>&1)
  [ "$output" = "1" ] || {
    TEST_FAILURE_REASON="stub-fathom-cursor -x failed: expected '1', got '$output'"
    return 1
  }
  
  # Test await-keypress
  output=$("$ROOT_DIR/spells/.imps/test/stub-await-keypress" 2>&1)
  [ "$output" = "enter" ] || {
    TEST_FAILURE_REASON="stub-await-keypress failed: expected 'enter', got '$output'"
    return 1
  }
  
  return 0
}

# Test 3: Verify symlinks to stubs work
test_stub_symlinks_work() {
  tmpdir=$(_make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Create symlink without stub- prefix (as tests do)
  ln -s "$ROOT_DIR/spells/.imps/test/stub-fathom-cursor" "$stub_dir/fathom-cursor"
  
  # Verify symlink was created
  [ -L "$stub_dir/fathom-cursor" ] || {
    TEST_FAILURE_REASON="symlink not created"
    return 1
  }
  
  # Verify symlink is executable
  [ -x "$stub_dir/fathom-cursor" ] || {
    TEST_FAILURE_REASON="symlink not executable"
    return 1
  }
  
  # Execute via symlink
  output=$("$stub_dir/fathom-cursor" 2>&1)
  [ "$output" = "1 1" ] || {
    TEST_FAILURE_REASON="symlink execution failed: expected '1 1', got '$output'"
    return 1
  }
  
  return 0
}

# Test 4: Verify stubs are found via PATH
test_stubs_found_via_path() {
  tmpdir=$(_make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Create symlinks for all stubs
  for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty await-keypress; do
    ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
  done
  
  # Test with stub_dir FIRST in PATH (critical!)
  old_path=$PATH
  PATH="$stub_dir:$PATH"
  
  # Verify command -v finds the stub
  found=$(command -v fathom-cursor 2>&1)
  case "$found" in
    "$stub_dir/fathom-cursor")
      : # correct
      ;;
    *)
      PATH=$old_path
      TEST_FAILURE_REASON="command -v found wrong fathom-cursor: $found (expected $stub_dir/fathom-cursor)"
      return 1
      ;;
  esac
  
  # Execute via PATH lookup
  output=$(fathom-cursor 2>&1)
  PATH=$old_path
  [ "$output" = "1 1" ] || {
    TEST_FAILURE_REASON="PATH execution failed: expected '1 1', got '$output'"
    return 1
  }
  
  return 0
}

# Test 5: Verify stubs override real commands
test_stubs_override_real_commands() {
  tmpdir=$(_make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Create a real command
  real_cmd="$tmpdir/real-bin/testcmd"
  mkdir -p "$(dirname "$real_cmd")"
  cat >"$real_cmd" <<'EOF'
#!/bin/sh
printf 'REAL\n'
EOF
  chmod +x "$real_cmd"
  
  # Create a stub for the same command
  cat >"$stub_dir/testcmd" <<'EOF'
#!/bin/sh
printf 'STUB\n'
EOF
  chmod +x "$stub_dir/testcmd"
  
  # With stub_dir first in PATH, should get stub
  old_path=$PATH
  PATH="$stub_dir:$tmpdir/real-bin:$PATH"
  output=$(testcmd 2>&1)
  PATH=$old_path
  
  [ "$output" = "STUB" ] || {
    TEST_FAILURE_REASON="stub did not override real command: got '$output'"
    return 1
  }
  
  return 0
}

# Test 6: Verify stubs work with _run_cmd
test_stubs_work_with_run_cmd() {
  tmpdir=$(_make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Create symlinks
  for stub in fathom-cursor await-keypress; do
    ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
  done
  
  # Create a test script that uses fathom-cursor
  test_script="$tmpdir/test-script.sh"
  cat >"$test_script" <<'EOF'
#!/bin/sh
set -eu
output=$(fathom-cursor)
printf 'result: %s\n' "$output"
EOF
  chmod +x "$test_script"
  
  # Run with stubs in PATH
  PATH="$stub_dir:$PATH" _run_cmd sh "$test_script"
  
  _assert_success || return 1
  _assert_output_contains "result: 1 1" || return 1
  
  return 0
}

# Test 7: Verify all stubs have correct self-execute pattern
test_stubs_have_self_execute_pattern() {
  failures=""
  
  for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty await-keypress; do
    stub_path="$ROOT_DIR/spells/.imps/test/stub-$stub"
    
    # Check for both stub name and unprefixed name in case statement
    if ! grep -qE "case.*\\\$0.*in" "$stub_path"; then
      failures="${failures}${failures:+, }$stub (no case statement)"
      continue
    fi
    
    # Check for stub name pattern
    if ! grep -qE "\*/stub-$stub\)" "$stub_path"; then
      failures="${failures}${failures:+, }$stub (missing */stub-$stub pattern)"
      continue
    fi
    
    # Check for unprefixed name pattern (for symlinks) - may be on same line with |
    unprefixed=$(printf '%s' "$stub" | sed 's/^stub-//')
    if ! grep -qE "\*/$unprefixed(\||\\))" "$stub_path"; then
      failures="${failures}${failures:+, }$stub (missing */$unprefixed pattern)"
    fi
  done
  
  if [ -n "$failures" ]; then
    TEST_FAILURE_REASON="stubs with incorrect self-execute pattern: $failures"
    return 1
  fi
  
  return 0
}

# Test 8: Verify stub documentation
test_stubs_have_documentation() {
  failures=""
  
  for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty await-keypress; do
    stub_path="$ROOT_DIR/spells/.imps/test/stub-$stub"
    
    # Check for opening comment (line 2 should start with #)
    line2=$(sed -n '2p' "$stub_path")
    case "$line2" in
      '#'*)
        : # good
        ;;
      *)
        failures="${failures}${failures:+, }$stub (missing opening comment)"
        ;;
    esac
  done
  
  if [ -n "$failures" ]; then
    TEST_FAILURE_REASON="stubs with missing documentation: $failures"
    return 1
  fi
  
  return 0
}

_run_test_case "stub files exist and are executable" test_stub_files_exist
_run_test_case "stubs execute directly" test_stubs_execute_directly
_run_test_case "stub symlinks work" test_stub_symlinks_work
_run_test_case "stubs found via PATH" test_stubs_found_via_path
_run_test_case "stubs override real commands" test_stubs_override_real_commands
_run_test_case "stubs work with _run_cmd" test_stubs_work_with_run_cmd
_run_test_case "stubs have self-execute pattern" test_stubs_have_self_execute_pattern
_run_test_case "stubs have documentation" test_stubs_have_documentation

_finish_tests
