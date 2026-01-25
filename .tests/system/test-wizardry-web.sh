#!/bin/sh
# Tests for the 'wizardry-web' spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_wizardry_web_help() {
  run_spell spells/system/wizardry-web --help
  assert_success
  assert_output_contains "Usage: wizardry-web"
  assert_output_contains "create"
  assert_output_contains "build"
}

test_wizardry_web_create_site() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir wizardry-web-test)
  export WIZARDRY_WEB_ROOT="$test_web_root"
  
  # Create a test site
  run_spell spells/system/wizardry-web create testsite
  assert_success
  
  # Verify site directory exists
  [ -d "$test_web_root/sites/testsite" ] || {
    TEST_FAILURE_REASON="site directory not created"
    return 1
  }
  
  # Verify default files exist
  [ -f "$test_web_root/sites/testsite/site/pages/index.md" ] || {
    TEST_FAILURE_REASON="index.md not created"
    return 1
  }
  
  # Cleanup
  rm -rf "$test_web_root"
}

test_wizardry_web_status() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir wizardry-web-test)
  export WIZARDRY_WEB_ROOT="$test_web_root"
  
  # Create a test site
  run_spell spells/system/wizardry-web create testsite
  assert_success
  
  # Check status
  run_spell spells/system/wizardry-web status testsite
  assert_success
  assert_output_contains "testsite"
  
  # Cleanup
  rm -rf "$test_web_root"
}

run_test_case "wizardry-web --help works" test_wizardry_web_help
run_test_case "wizardry-web can create site" test_wizardry_web_create_site
run_test_case "wizardry-web can show status" test_wizardry_web_status

finish_tests
