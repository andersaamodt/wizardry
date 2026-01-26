#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_first_priority() {
  # Check if xattr support is available
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test1.txt"
  printf 'test\n' > "$testfile"
  
  # Try to hash the file - if this fails, skip the test
  run_spell "spells/crypto/hashchant" "$testfile"
  printf 'STATUS=%s\n' "$STATUS" >&2
  printf 'OUTPUT=%s\n' "$OUTPUT" >&2
  printf 'ERROR=%s\n' "$ERROR" >&2
  if [ "$STATUS" -ne 0 ]; then
    export TEST_SKIP_REASON="xattr support not available"
    return 222
  fi
  
  # Prioritize first file
  run_spell "spells/priorities/prioritize" "$testfile"
  assert_success || return 1
  assert_output_contains "first priority" || return 1
}

run_test_case "prioritize creates first priority" test_first_priority
finish_tests
