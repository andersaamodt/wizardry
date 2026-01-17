#!/bin/sh
# Tests for attribute-get imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_xattr_read_value_exists() {
  run_cmd sh -c 'command -v attribute-get'
  assert_success || return 1
}

test_xattr_read_value_with_mock_xattr() {
  skip-if-compiled || return $?
  # Create test environment with mock xattr
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/testfile.txt"
  printf "test content\n" > "$testfile"
  
  mkdir -p "$tmpdir/bin"
  cat > "$tmpdir/bin/xattr" <<'STUB'
#!/bin/sh
# Mock xattr -p command
if [ "$1" = "-p" ]; then
  case "$2" in
    user.name) printf "Alice" ;;
    user.email) printf "alice@example.com" ;;
    *) exit 1 ;;
  esac
fi
STUB
  chmod +x "$tmpdir/bin/xattr"
  
  cat > "$tmpdir/bin/attribute-tool-check" <<'STUB'
#!/bin/sh
[ "$1" = "xattr" ]
STUB
  chmod +x "$tmpdir/bin/attribute-tool-check"
  
  run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && attribute-get user.name "'"$testfile"'"'
  assert_success || return 1
  assert_output_contains "Alice" || return 1
  
  rm -rf "$tmpdir"
}

test_xattr_read_value_fallback_to_attr() {
  skip-if-compiled || return $?
  # Test fallback to attr command
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/testfile.txt"
  printf "test content\n" > "$testfile"
  
  mkdir -p "$tmpdir/bin"
  cat > "$tmpdir/bin/attr" <<'STUB'
#!/bin/sh
# Mock attr -g command (has header line that should be stripped)
if [ "$1" = "-g" ]; then
  printf 'Attribute "%s" had a 5 byte value for %s:\n' "$2" "$3"
  printf 'Alice'
fi
STUB
  chmod +x "$tmpdir/bin/attr"
  
  cat > "$tmpdir/bin/attribute-tool-check" <<'STUB'
#!/bin/sh
[ "$1" = "attr" ]
STUB
  chmod +x "$tmpdir/bin/attribute-tool-check"
  
  run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && attribute-get user.name "'"$testfile"'"'
  assert_success || return 1
  assert_output_contains "Alice" || return 1
  # Should NOT contain the header line
  if printf '%s' "$OUTPUT" | grep -q "Attribute"; then
    return 1
  fi
  
  rm -rf "$tmpdir"
}

test_xattr_read_value_returns_error_for_missing_key() {
  skip-if-compiled || return $?
  # Should return 1 when key doesn't exist
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/testfile.txt"
  printf "test content\n" > "$testfile"
  
  mkdir -p "$tmpdir/bin"
  cat > "$tmpdir/bin/xattr" <<'STUB'
#!/bin/sh
# Return error for non-existent key
exit 1
STUB
  chmod +x "$tmpdir/bin/xattr"
  
  cat > "$tmpdir/bin/attribute-tool-check" <<'STUB'
#!/bin/sh
[ "$1" = "xattr" ]
STUB
  chmod +x "$tmpdir/bin/attribute-tool-check"
  
  run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && attribute-get nonexistent.key "'"$testfile"'"'
  assert_failure || return 1
  
  rm -rf "$tmpdir"
}

run_test_case "attribute-get exists" test_xattr_read_value_exists
run_test_case "attribute-get with mock xattr" test_xattr_read_value_with_mock_xattr
run_test_case "attribute-get fallback to attr" test_xattr_read_value_fallback_to_attr
run_test_case "attribute-get returns error for missing key" test_xattr_read_value_returns_error_for_missing_key

finish_tests
