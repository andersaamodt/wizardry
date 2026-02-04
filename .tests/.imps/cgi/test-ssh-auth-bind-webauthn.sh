#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_ssh_auth_bind_webauthn_exists() {
  [ -x "spells/.imps/cgi/ssh-auth-bind-webauthn" ]
}

test_ssh_auth_bind_webauthn_missing_params() {
  export QUERY_STRING=""
  output=$(spells/.imps/cgi/ssh-auth-bind-webauthn 2>&1)
  printf '%s' "$output" | grep -q '"success":false'
}

run_test_case "ssh-auth-bind-webauthn is executable" test_ssh_auth_bind_webauthn_exists
run_test_case "ssh-auth-bind-webauthn rejects missing params" test_ssh_auth_bind_webauthn_missing_params
finish_tests
