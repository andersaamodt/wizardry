#!/bin/sh
# Tests for the 'wizardry' spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_web_wizardry_help() {
  run_spell spells/web/wizardry --help
  assert_success
  assert_output_contains "Usage: wizardry"
  assert_output_contains "create"
  assert_output_contains "build"
}

test_web_wizardry_create_site() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Create a test site
  run_spell spells/web/wizardry create testsite
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

test_web_wizardry_status() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Create a test site
  run_spell spells/web/wizardry create testsite
  assert_success
  
  # Check status
  run_spell spells/web/wizardry status testsite
  assert_success
  assert_output_contains "testsite"
  
  # Cleanup
  rm -rf "$test_web_root"
}

run_test_case "wizardry --help works" test_web_wizardry_help
run_test_case "wizardry can create site" test_web_wizardry_create_site
run_test_case "wizardry can show status" test_web_wizardry_status

finish_tests
