#!/bin/sh
# Test stub-ask-text-simple imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_ask_text_simple "$tmpdir"
  [ -x "$tmpdir/ask-text" ]
}

test_stub_uses_env_var() {
  tmpdir=$(make_tempdir)
  stub_ask_text_simple "$tmpdir"
  export ASK_TEXT_RESPONSE="from env"
  result=$("$tmpdir/ask-text")
  [ "$result" = "from env" ]
}

run_test_case "stub-ask-text-simple creates executable" test_creates_stub
run_test_case "stub-ask-text-simple uses ASK_TEXT_RESPONSE" test_stub_uses_env_var

finish_tests
