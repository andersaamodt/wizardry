#!/bin/sh
# Test stub-memorize-command imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_memorize_command "$tmpdir"
  [ -x "$tmpdir/memorize" ]
}

test_stub_adds_command() {
  tmpdir=$(make_tempdir)
  stub_memorize_command "$tmpdir"
  export WIZARDRY_CAST_DIR="$tmpdir/cast"
  "$tmpdir/memorize" add testcmd echo hello
  [ -f "$tmpdir/cast/.memorized" ]
  [ -x "$tmpdir/cast/testcmd" ]
}

test_stub_lists_commands() {
  tmpdir=$(make_tempdir)
  stub_memorize_command "$tmpdir"
  export WIZARDRY_CAST_DIR="$tmpdir/cast"
  "$tmpdir/memorize" add testcmd echo hello
  result=$("$tmpdir/memorize" list)
  case "$result" in
    *testcmd*) : ;;
    *) return 1 ;;
  esac
}

run_test_case "stub-memorize-command creates executable" test_creates_stub
run_test_case "stub-memorize-command adds commands" test_stub_adds_command
run_test_case "stub-memorize-command lists commands" test_stub_lists_commands

finish_tests
