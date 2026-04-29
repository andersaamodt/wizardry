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

test_ssh_auth_check_session_rejects_path_token() {
  skip-if-compiled || return $?

  sites_dir=$(temp-dir ssh-auth-sites)
  auth_dir="$sites_dir/.sitedata/testsite/ssh-auth"
  mkdir -p "$auth_dir/sessions"
  printf '%s\n' '{"username":"root","fingerprint":"outside"}' > "$auth_dir/escape"

  QUERY_STRING='session_token=..%2Fescape' \
    WIZARDRY_SITE_NAME=testsite WIZARDRY_SITES_DIR="$sites_dir" \
    run_cmd spells/.imps/cgi/ssh-auth-check-session
  assert_success || return 1
  assert_output_contains '"authenticated":false' || return 1
  if printf '%s' "$OUTPUT" | grep -F '"authenticated":true' >/dev/null 2>&1; then
    TEST_FAILURE_REASON="ssh-auth-check-session authenticated a path-shaped token"
    rm -rf "$sites_dir"
    return 1
  fi

  rm -rf "$sites_dir"
}

run_test_case "ssh-auth-check-session is executable" test_ssh_auth_check_session_exists
run_test_case "ssh-auth-check-session handles missing token" test_ssh_auth_check_session_missing_token
run_test_case "ssh-auth-check-session rejects path-shaped token" \
  test_ssh_auth_check_session_rejects_path_token
finish_tests
