#!/bin/sh
# Test stub-failing-menu imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_failing_menu "$tmpdir"
  [ -x "$tmpdir/menu" ]
}

test_stub_exits_with_7() {
  tmpdir=$(make_tempdir)
  stub_failing_menu "$tmpdir"
  export MENU_LOG="$tmpdir/menu.log"
  if "$tmpdir/menu" option1 option2 2>/dev/null; then
    return 1
  else
    exitcode=$?
    [ "$exitcode" -eq 7 ]
  fi
}

run_test_case "stub-failing-menu creates executable" test_creates_stub
run_test_case "stub-failing-menu exits with code 7" test_stub_exits_with_7

finish_tests
