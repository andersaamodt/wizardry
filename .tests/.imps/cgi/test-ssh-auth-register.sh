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

test_ssh_auth_register_rejects_path_username() {
  skip-if-compiled || return $?

  sites_dir=$(temp-dir ssh-auth-sites)
  QUERY_STRING='username=..%2Fescape&ssh_public_key=ssh-ed25519+AAAAC3NzaC1lZDI1NTE5AAAAItest' \
    WIZARDRY_SITE_NAME=testsite WIZARDRY_SITES_DIR="$sites_dir" \
    run_cmd spells/.imps/cgi/ssh-auth-register
  assert_success || return 1
  assert_output_contains '"success":false' || return 1
  assert_output_contains 'Invalid username' || return 1

  if [ -e "$sites_dir/.sitedata/testsite/ssh-auth/escape" ]; then
    TEST_FAILURE_REASON="ssh-auth-register wrote outside users directory for path username"
    rm -rf "$sites_dir"
    return 1
  fi

  rm -rf "$sites_dir"
}

run_test_case "ssh-auth-register is executable" test_ssh_auth_register_exists
run_test_case "ssh-auth-register rejects missing params" test_ssh_auth_register_missing_params
run_test_case "ssh-auth-register creates fingerprint" test_ssh_auth_register_creates_fingerprint
run_test_case "ssh-auth-register rejects path-shaped username" \
  test_ssh_auth_register_rejects_path_username
finish_tests
