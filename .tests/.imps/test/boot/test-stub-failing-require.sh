#!/bin/sh
# Test stub-failing-require imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_failing_require "$tmpdir"
  [ -x "$tmpdir/require" ]
}

test_stub_fails_with_message() {
  tmpdir=$(make_tempdir)
  stub_failing_require "$tmpdir"
  output=$("$tmpdir/require" 2>&1 || true)
  case "$output" in
    *"menu"*) : ;;
    *) return 1 ;;
  esac
}

run_test_case "stub-failing-require creates executable" test_creates_stub
run_test_case "stub-failing-require fails with menu message" test_stub_fails_with_message

finish_tests
