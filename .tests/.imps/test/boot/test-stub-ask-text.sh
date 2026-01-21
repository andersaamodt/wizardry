#!/bin/sh
# Test stub-ask-text imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_ask_text "$tmpdir" "test response"
  [ -x "$tmpdir/ask-text" ]
}

test_stub_returns_response() {
  tmpdir=$(make_tempdir)
  stub_ask_text "$tmpdir" "hello world"
  result=$("$tmpdir/ask-text")
  [ "$result" = "hello world" ]
}

run_test_case "stub-ask-text creates executable" test_creates_stub
run_test_case "stub-ask-text returns fixed response" test_stub_returns_response

finish_tests
