#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_valid_session_tokens() {
  run_spell "spells/.imps/cgi/validate-session-token" "abcDEF_123-xyz.9"
  [ "$STATUS" -eq 0 ] || return 1
}

test_invalid_session_tokens() {
  run_spell "spells/.imps/cgi/validate-session-token" "../escape"
  [ "$STATUS" -ne 0 ] || return 1

  run_spell "spells/.imps/cgi/validate-session-token" "abc/def"
  [ "$STATUS" -ne 0 ] || return 1

  run_spell "spells/.imps/cgi/validate-session-token" "abc+def="
  [ "$STATUS" -ne 0 ] || return 1
}

run_test_case "validates safe session tokens" test_valid_session_tokens
run_test_case "rejects path-shaped session tokens" test_invalid_session_tokens
finish_tests
