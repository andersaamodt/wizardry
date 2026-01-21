#!/bin/sh
# Test stub-menu imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_menu "$tmpdir"
  [ -x "$tmpdir/menu" ]
}

test_stub_logs_invocations() {
  tmpdir=$(make_tempdir)
  stub_menu "$tmpdir"
  export MENU_LOG="$tmpdir/menu.log"
  (
    trap '' INT
    "$tmpdir/menu" option1 option2 2>/dev/null || true
  )
  [ -f "$MENU_LOG" ]
  grep -q "option1" "$MENU_LOG"
}

run_test_case "stub-menu creates executable" test_creates_stub
run_test_case "stub-menu logs menu calls" test_stub_logs_invocations

finish_tests
