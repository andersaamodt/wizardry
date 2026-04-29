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

test_ssh_auth_login_generates_path_safe_token() {
  skip-if-compiled || return $?

  sites_dir=$(temp-dir ssh-auth-sites)
  user_dir="$sites_dir/.sitedata/testsite/ssh-auth/users/alice"
  mkdir -p "$user_dir/delegates"
  printf '%s' 'fingerprint123' > "$user_dir/ssh_fingerprint"
  printf '%s\n' '{"credential_id":"cred123"}' > "$user_dir/delegates/delegate1"

  QUERY_STRING='credential_id=cred123' \
    WIZARDRY_SITE_NAME=testsite WIZARDRY_SITES_DIR="$sites_dir" \
    run_cmd spells/.imps/cgi/ssh-auth-login
  assert_success || return 1
  assert_output_contains '"success":true' || return 1

  session_token=$(printf '%s' "$OUTPUT" | sed -n 's/.*"session_token":"\([^"]*\)".*/\1/p')
  if ! validate-session-token "$session_token"; then
    TEST_FAILURE_REASON="ssh-auth-login generated a path-unsafe session token"
    rm -rf "$sites_dir"
    return 1
  fi

  rm -rf "$sites_dir"
}

run_test_case "ssh-auth-login is executable" test_ssh_auth_login_exists
run_test_case "ssh-auth-login rejects missing params" test_ssh_auth_login_missing_params
run_test_case "ssh-auth-login generates path-safe token" \
  test_ssh_auth_login_generates_path_safe_token
finish_tests
