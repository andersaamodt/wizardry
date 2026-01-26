#!/bin/sh
# Tests for the 'create-site' spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_web_create_site_help() {
  run_spell spells/web/create-site --help
  assert_success
  assert_output_contains "Usage: create-site"
}

test_web_create_site_creates_structure() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Create a test site
  run_spell spells/web/create-site mytestsite
  assert_success
  
  # Verify directory structure
  [ -d "$test_web_root/mytestsite/site/pages" ] || {
    TEST_FAILURE_REASON="pages directory not created"
    return 1
  }
  [ -d "$test_web_root/mytestsite/site/uploads" ] || {
    TEST_FAILURE_REASON="uploads directory not created"
    return 1
  }
  [ -d "$test_web_root/mytestsite/site/static" ] || {
    TEST_FAILURE_REASON="static directory not created"
    return 1
  }
  [ -d "$test_web_root/mytestsite/build" ] || {
    TEST_FAILURE_REASON="build directory not created"
    return 1
  }
  
  # Cleanup
  rm -rf "$test_web_root"
}

run_test_case "create-site --help works" test_web_create_site_help
run_test_case "create-site creates structure" test_web_create_site_creates_structure

finish_tests
