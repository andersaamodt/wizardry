#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_hash_failure_message() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  printf 'test\n' > "$testfile"
  
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  printf '#!/bin/sh\nexit 1\n' >"$stub_dir/hashchant"
  chmod +x "$stub_dir/hashchant"
  
  PATH="$stub_dir:$PATH" run_spell "spells/priorities/prioritize" "$testfile"
  printf 'STATUS=%s\n' "$STATUS" >&2
  printf 'ERROR=%s\n' "$ERROR" >&2
  assert_failure || return 1
  assert_error_contains "hashchant" || return 1
}

run_test_case "hash fail" test_hash_failure_message
finish_tests
