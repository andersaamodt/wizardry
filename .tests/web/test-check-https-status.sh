#!/bin/sh
# Test check-https-status spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_check_https_status_help() {
  run_spell spells/web/check-https-status --help
  assert_success
  assert_output_contains "Usage:"
}

test_check_https_status_not_configured() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Create a test site directory
  mkdir -p "$test_web_root/mytestsite"
  printf 'site-name=mytestsite\nport=8080\ndomain=localhost\nhttps=false\n' > "$test_web_root/mytestsite/site.conf"
  
  # Run check-https-status - should fail (return 1) when HTTPS not configured
  run_spell spells/web/check-https-status mytestsite
  assert_status 1
  
  # Cleanup
  rm -rf "$test_web_root"
}

test_check_https_status_configured() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Create a test site directory
  mkdir -p "$test_web_root/mytestsite"
  
  # Create a fake certificate file
  test_cert_dir=$(temp-dir cert-test)
  test_cert="$test_cert_dir/fullchain.pem"
  printf 'fake cert\n' > "$test_cert"
  
  printf 'site-name=mytestsite\nport=8080\ndomain=example.com\nhttps=true\ncert-path=%s\n' "$test_cert" > "$test_web_root/mytestsite/site.conf"
  
  # Run check-https-status - should succeed (return 0) when HTTPS configured
  run_spell spells/web/check-https-status mytestsite
  assert_success
  
  # Cleanup
  rm -rf "$test_web_root"
  rm -rf "$test_cert_dir"
}

run_test_case "check-https-status --help" test_check_https_status_help
run_test_case "check-https-status returns 1 when HTTPS not configured" test_check_https_status_not_configured
run_test_case "check-https-status returns 0 when HTTPS configured" test_check_https_status_configured

finish_tests
