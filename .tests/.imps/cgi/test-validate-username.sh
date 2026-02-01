#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_valid_usernames() {
  run_spell "spells/.imps/cgi/validate-username" "alice"
  [ "$STATUS" -eq 0 ] || return 1
  
  run_spell "spells/.imps/cgi/validate-username" "user_123"
  [ "$STATUS" -eq 0 ] || return 1
  
  run_spell "spells/.imps/cgi/validate-username" "test-user"
  [ "$STATUS" -eq 0 ] || return 1
}

test_invalid_usernames() {
  # Special characters
  run_spell "spells/.imps/cgi/validate-username" "user@email"
  [ "$STATUS" -ne 0 ] || return 1
  
  run_spell "spells/.imps/cgi/validate-username" "user name"
  [ "$STATUS" -ne 0 ] || return 1
  
  run_spell "spells/.imps/cgi/validate-username" "user;rm"
  [ "$STATUS" -ne 0 ] || return 1
  
  # Path traversal
  run_spell "spells/.imps/cgi/validate-username" "../admin"
  [ "$STATUS" -ne 0 ] || return 1
  
  # Empty
  run_spell "spells/.imps/cgi/validate-username" ""
  [ "$STATUS" -ne 0 ] || return 1
}

run_test_case "validates valid usernames" test_valid_usernames
run_test_case "rejects invalid usernames" test_invalid_usernames
finish_tests
