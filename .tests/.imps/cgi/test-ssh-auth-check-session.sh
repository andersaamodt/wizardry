#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_ssh_auth_check_session_exists() {
  [ -x "spells/.imps/cgi/ssh-auth-check-session" ]
}

test_ssh_auth_check_session_missing_token() {
  export QUERY_STRING=""
  output=$(spells/.imps/cgi/ssh-auth-check-session 2>&1)
  printf '%s' "$output" | grep -q '"authenticated":false'
}

run_test_case "ssh-auth-check-session is executable" test_ssh_auth_check_session_exists
run_test_case "ssh-auth-check-session handles missing token" test_ssh_auth_check_session_missing_token
finish_tests
