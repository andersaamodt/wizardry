#!/bin/sh
# Tests for attr-set imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_xattr_write_value_exists() {
  run_cmd sh -c 'command -v attr-set'
  assert_success || return 1
}

test_xattr_write_value_with_mock_attr() {
  skip-if-compiled || return $?
  # Create test environment with mock attr
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/testfile.txt"
  printf "test content\n" > "$testfile"
  logfile="$tmpdir/attr.log"
  
  mkdir -p "$tmpdir/bin"
  cat > "$tmpdir/bin/attr" <<STUB
#!/bin/sh
# Mock attr -s command - log the call and succeed
if [ "\$1" = "-s" ]; then
  printf 'key=%s value=%s file=%s\n' "\$2" "\$4" "\$5" > "$logfile"
  printf 'Attribute "%s" set to a %d byte value for %s:\n' "\$2" "\${#4}" "\$5"
  exit 0
fi
exit 1
STUB
  chmod +x "$tmpdir/bin/attr"
  
  cat > "$tmpdir/bin/attr-tool-check" <<'STUB'
#!/bin/sh
[ "$1" = "attr" ]
STUB
  chmod +x "$tmpdir/bin/attr-tool-check"
  
  run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && attr-set user.name Alice "'"$testfile"'"'
  assert_success || return 1
  
  # Verify the mock was called with correct parameters
  run_cmd cat "$logfile"
  assert_success || return 1
  assert_output_contains "key=user.name" || return 1
  assert_output_contains "value=Alice" || return 1
  
  rm -rf "$tmpdir"
}

test_xattr_write_value_fallback_to_xattr() {
  skip-if-compiled || return $?
  # Test fallback to xattr command (macOS)
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/testfile.txt"
  printf "test content\n" > "$testfile"
  logfile="$tmpdir/xattr.log"
  
  mkdir -p "$tmpdir/bin"
  cat > "$tmpdir/bin/xattr" <<STUB
#!/bin/sh
# Mock xattr -w command
if [ "\$1" = "-w" ]; then
  printf 'key=%s value=%s file=%s\n' "\$2" "\$3" "\$4" > "$logfile"
  exit 0
fi
exit 1
STUB
  chmod +x "$tmpdir/bin/xattr"
  
  cat > "$tmpdir/bin/attr-tool-check" <<'STUB'
#!/bin/sh
[ "$1" = "xattr" ]
STUB
  chmod +x "$tmpdir/bin/attr-tool-check"
  
  run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && attr-set user.email bob@example.com "'"$testfile"'"'
  assert_success || return 1
  
  # Verify the mock was called with correct parameters
  run_cmd cat "$logfile"
  assert_success || return 1
  assert_output_contains "key=user.email" || return 1
  assert_output_contains "value=bob@example.com" || return 1
  
  rm -rf "$tmpdir"
}

test_xattr_write_value_returns_error_when_no_helpers() {
  skip-if-compiled || return $?
  # Should return 1 when no xattr helpers are available
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/testfile.txt"
  printf "test content\n" > "$testfile"
  
  mkdir -p "$tmpdir/bin"
  cat > "$tmpdir/bin/attr-tool-check" <<'STUB'
#!/bin/sh
# All helpers unavailable
exit 1
STUB
  chmod +x "$tmpdir/bin/attr-tool-check"
  
  run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && attr-set user.key value "'"$testfile"'"'
  assert_failure || return 1
  
  rm -rf "$tmpdir"
}

run_test_case "attr-set exists" test_xattr_write_value_exists
run_test_case "attr-set with mock attr" test_xattr_write_value_with_mock_attr
run_test_case "attr-set fallback to xattr" test_xattr_write_value_fallback_to_xattr
run_test_case "attr-set returns error when no helpers" test_xattr_write_value_returns_error_when_no_helpers

finish_tests
