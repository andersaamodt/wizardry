#!/bin/sh
# Tests for list-attributes imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_attr_list_exists() {
  run_cmd sh -c 'command -v list-attributes'
  assert_success || return 1
}

test_attr_list_with_mock_xattr() {
  skip-if-compiled || return $?
  # Create a test file and mock xattr command
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/testfile.txt"
  printf "test content\n" > "$testfile"
  
  # Create stub xattr that returns keys
  mkdir -p "$tmpdir/bin"
  cat > "$tmpdir/bin/xattr" <<'STUB'
#!/bin/sh
printf 'user.key1\nuser.key2\nuser.key3\n'
STUB
  chmod +x "$tmpdir/bin/xattr"
  
  # Create stub attribute-tool-check that accepts xattr
  cat > "$tmpdir/bin/attribute-tool-check" <<'STUB'
#!/bin/sh
[ "$1" = "xattr" ]
STUB
  chmod +x "$tmpdir/bin/attribute-tool-check"
  
  # Run list-attributes with mocked PATH
  run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && list-attributes "'"$testfile"'"'
  assert_success || return 1
  assert_output_contains "user.key1" || return 1
  assert_output_contains "user.key2" || return 1
  
  rm -rf "$tmpdir"
}

test_attr_list_fallback_to_attr() {
  skip-if-compiled || return $?
  # Test fallback to attr command when xattr not available
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/testfile.txt"
  printf "test content\n" > "$testfile"
  
  mkdir -p "$tmpdir/bin"
  # Create stub attr that returns keys
  cat > "$tmpdir/bin/attr" <<'STUB'
#!/bin/sh
printf 'Attribute "user.name" had a 5 byte value\n'
printf 'Attribute "user.email" had a 10 byte value\n'
STUB
  chmod +x "$tmpdir/bin/attr"
  
  # Create stub attribute-tool-check that only accepts attr
  cat > "$tmpdir/bin/attribute-tool-check" <<'STUB'
#!/bin/sh
[ "$1" = "attr" ]
STUB
  chmod +x "$tmpdir/bin/attribute-tool-check"
  
  run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && list-attributes "'"$testfile"'"'
  assert_success || return 1
  assert_output_contains "user.name" || return 1
  assert_output_contains "user.email" || return 1
  
  rm -rf "$tmpdir"
}

test_attr_list_returns_error_when_no_attrs() {
  skip-if-compiled || return $?
  # Should return 1 when no attributes found
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/testfile.txt"
  printf "test content\n" > "$testfile"
  
  mkdir -p "$tmpdir/bin"
  # Create stub that returns empty
  cat > "$tmpdir/bin/xattr" <<'STUB'
#!/bin/sh
# Return nothing
STUB
  chmod +x "$tmpdir/bin/xattr"
  
  cat > "$tmpdir/bin/attribute-tool-check" <<'STUB'
#!/bin/sh
[ "$1" = "xattr" ]
STUB
  chmod +x "$tmpdir/bin/attribute-tool-check"
  
  run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && list-attributes "'"$testfile"'"'
  assert_failure || return 1
  
  rm -rf "$tmpdir"
}

run_test_case "list-attributes exists" test_attr_list_exists
run_test_case "list-attributes with mock xattr" test_attr_list_with_mock_xattr
run_test_case "list-attributes fallback to attr" test_attr_list_fallback_to_attr
run_test_case "list-attributes returns error when no attrs" test_attr_list_returns_error_when_no_attrs

finish_tests
