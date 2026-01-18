#!/bin/sh
# Test coverage for get-attribute-batch imp

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_batch_read_multiple_attrs() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  touch "$testfile"
  
  # Create mock xattr that returns different values for different attributes
  mkdir -p "$tmpdir/bin"
  cat > "$tmpdir/bin/xattr" <<'STUB'
#!/bin/sh
if [ "$1" = "-p" ]; then
  case "$2" in
    user.echelon) printf "5" ;;
    user.priority) printf "3" ;;
    user.checked) printf "1" ;;
    *) exit 1 ;;
  esac
fi
STUB
  chmod +x "$tmpdir/bin/xattr"
  
  cat > "$tmpdir/bin/check-attribute-tool" <<'STUB'
#!/bin/sh
[ "$1" = "xattr" ]
STUB
  chmod +x "$tmpdir/bin/check-attribute-tool"
  
  # Read all three at once
  run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && get-attribute-batch "'"$testfile"'" echelon priority checked'
  assert_success || return 1
  assert_output_contains "echelon=5" || return 1
  assert_output_contains "priority=3" || return 1
  assert_output_contains "checked=1" || return 1
}

test_batch_read_missing_attrs() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  touch "$testfile"
  
  # Mock xattr that only has echelon
  mkdir -p "$tmpdir/bin"
  cat > "$tmpdir/bin/xattr" <<'STUB'
#!/bin/sh
if [ "$1" = "-p" ]; then
  case "$2" in
    user.echelon) printf "2" ;;
    *) exit 1 ;;
  esac
fi
STUB
  chmod +x "$tmpdir/bin/xattr"
  
  cat > "$tmpdir/bin/check-attribute-tool" <<'STUB'
#!/bin/sh
[ "$1" = "xattr" ]
STUB
  chmod +x "$tmpdir/bin/check-attribute-tool"
  
  # Try to read three (only one exists)
  run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && get-attribute-batch "'"$testfile"'" echelon priority checked'
  assert_success || return 1
  assert_output_contains "echelon=2" || return 1
  # Should not contain missing attributes
  if printf '%s' "$OUTPUT" | grep -q "priority="; then
    return 1
  fi
}

test_batch_read_no_attrs() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  touch "$testfile"
  
  # Mock xattr that has no attributes
  mkdir -p "$tmpdir/bin"
  cat > "$tmpdir/bin/xattr" <<'STUB'
#!/bin/sh
exit 1
STUB
  chmod +x "$tmpdir/bin/xattr"
  
  cat > "$tmpdir/bin/check-attribute-tool" <<'STUB'
#!/bin/sh
[ "$1" = "xattr" ]
STUB
  chmod +x "$tmpdir/bin/check-attribute-tool"
  
  # Try to read attributes that don't exist
  run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && get-attribute-batch "'"$testfile"'" echelon priority checked'
  assert_failure || return 1
}

run_test_case "batch read multiple attributes" test_batch_read_multiple_attrs
run_test_case "batch read with missing attributes" test_batch_read_missing_attrs
run_test_case "batch read with no attributes" test_batch_read_no_attrs
finish_tests
