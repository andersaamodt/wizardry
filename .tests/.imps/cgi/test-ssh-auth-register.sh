#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_ssh_auth_register_exists() {
  [ -x "spells/.imps/cgi/ssh-auth-register" ]
}

test_ssh_auth_register_missing_params() {
  export QUERY_STRING=""
  output=$(spells/.imps/cgi/ssh-auth-register 2>&1)
  printf '%s' "$output" | grep -q '"success":false'
}

test_ssh_auth_register_creates_fingerprint() {
  export QUERY_STRING="username=testuser&ssh_public_key=ssh-ed25519+AAAAC3NzaC1lZDI1NTE5AAAAItest"
  output=$(spells/.imps/cgi/ssh-auth-register 2>&1)
  printf '%s' "$output" | grep -q '"success":true' &&
  printf '%s' "$output" | grep -q '"fingerprint"' &&
  printf '%s' "$output" | grep -q '"challenge"'
}

run_test_case "ssh-auth-register is executable" test_ssh_auth_register_exists
run_test_case "ssh-auth-register rejects missing params" test_ssh_auth_register_missing_params
run_test_case "ssh-auth-register creates fingerprint" test_ssh_auth_register_creates_fingerprint
finish_tests
