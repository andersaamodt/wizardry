#!/bin/sh
# Test stub-require-command imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_require_command "$tmpdir"
  [ -x "$tmpdir/require-command" ]
}

test_stub_logs_and_succeeds() {
  tmpdir=$(make_tempdir)
  stub_require_command "$tmpdir"
  export REQUIRE_LOG="$tmpdir/require.log"
  "$tmpdir/require-command" git "Git is required"
  [ -f "$REQUIRE_LOG" ]
  grep -q "git" "$REQUIRE_LOG"
}

run_test_case "stub-require-command creates executable" test_creates_stub
run_test_case "stub-require-command logs and succeeds" test_stub_logs_and_succeeds

finish_tests
