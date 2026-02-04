#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_ssh_auth_login_exists() {
  [ -x "spells/.imps/cgi/ssh-auth-login" ]
}

test_ssh_auth_login_missing_params() {
  export QUERY_STRING=""
  output=$(spells/.imps/cgi/ssh-auth-login 2>&1)
  printf '%s' "$output" | grep -q '"success":false'
}

run_test_case "ssh-auth-login is executable" test_ssh_auth_login_exists
run_test_case "ssh-auth-login rejects missing params" test_ssh_auth_login_missing_params
finish_tests
