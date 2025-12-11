#!/bin/sh
# Tests for xattr-list-keys imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_xattr_list_keys_exists() {
  _run_cmd command -v xattr-list-keys
  _assert_success || return 1
}

test_xattr_list_keys_with_mock_xattr() {
  skip-if-compiled || return $?
  # Create a test file and mock xattr command
  tmpdir=$(make-tempdir xattr-test)
  testfile="$tmpdir/testfile.txt"
  printf "test content\n" > "$testfile"
  
  # Create stub xattr that returns keys
  mkdir -p "$tmpdir/bin"
  cat > "$tmpdir/bin/xattr" <<'STUB'
#!/bin/sh
printf 'user.key1\nuser.key2\nuser.key3\n'
STUB
  chmod +x "$tmpdir/bin/xattr"
  
  # Create stub xattr-helper-usable that accepts xattr
  cat > "$tmpdir/bin/xattr-helper-usable" <<'STUB'
#!/bin/sh
[ "$1" = "xattr" ]
STUB
  chmod +x "$tmpdir/bin/xattr-helper-usable"
  
  # Run xattr-list-keys with mocked PATH
  _run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && xattr-list-keys "'"$testfile"'"'
  _assert_success || return 1
  _assert_output_contains "user.key1" || return 1
  _assert_output_contains "user.key2" || return 1
  
  rm -rf "$tmpdir"
}

test_xattr_list_keys_fallback_to_attr() {
  skip-if-compiled || return $?
  # Test fallback to attr command when xattr not available
  tmpdir=$(make-tempdir xattr-test)
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
  
  # Create stub xattr-helper-usable that only accepts attr
  cat > "$tmpdir/bin/xattr-helper-usable" <<'STUB'
#!/bin/sh
[ "$1" = "attr" ]
STUB
  chmod +x "$tmpdir/bin/xattr-helper-usable"
  
  _run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && xattr-list-keys "'"$testfile"'"'
  _assert_success || return 1
  _assert_output_contains "user.name" || return 1
  _assert_output_contains "user.email" || return 1
  
  rm -rf "$tmpdir"
}

test_xattr_list_keys_returns_error_when_no_attrs() {
  skip-if-compiled || return $?
  # Should return 1 when no attributes found
  tmpdir=$(make-tempdir xattr-test)
  testfile="$tmpdir/testfile.txt"
  printf "test content\n" > "$testfile"
  
  mkdir -p "$tmpdir/bin"
  # Create stub that returns empty
  cat > "$tmpdir/bin/xattr" <<'STUB'
#!/bin/sh
# Return nothing
STUB
  chmod +x "$tmpdir/bin/xattr"
  
  cat > "$tmpdir/bin/xattr-helper-usable" <<'STUB'
#!/bin/sh
[ "$1" = "xattr" ]
STUB
  chmod +x "$tmpdir/bin/xattr-helper-usable"
  
  _run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && xattr-list-keys "'"$testfile"'"'
  _assert_failure || return 1
  
  rm -rf "$tmpdir"
}

_run_test_case "xattr-list-keys exists" test_xattr_list_keys_exists
_run_test_case "xattr-list-keys with mock xattr" test_xattr_list_keys_with_mock_xattr
_run_test_case "xattr-list-keys fallback to attr" test_xattr_list_keys_fallback_to_attr
_run_test_case "xattr-list-keys returns error when no attrs" test_xattr_list_keys_returns_error_when_no_attrs

_finish_tests
