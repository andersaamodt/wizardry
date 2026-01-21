#!/bin/sh
# Test stub-require-command-simple imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_require_command_simple "$tmpdir"
  [ -x "$tmpdir/require-command" ]
}

test_stub_always_succeeds() {
  tmpdir=$(make_tempdir)
  stub_require_command_simple "$tmpdir"
  "$tmpdir/require-command" git "Git is required"
}

run_test_case "stub-require-command-simple creates executable" test_creates_stub
run_test_case "stub-require-command-simple always succeeds" test_stub_always_succeeds

finish_tests
