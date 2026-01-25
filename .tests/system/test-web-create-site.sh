#!/bin/sh
# Tests for the 'web-create-site' spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_web_create_site_help() {
  run_spell spells/system/web-create-site --help
  assert_success
  assert_output_contains "Usage: web-create-site"
}

test_web_create_site_creates_structure() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir wizardry-web-test)
  export WIZARDRY_WEB_ROOT="$test_web_root"
  
  # Create a test site
  run_spell spells/system/web-create-site mytestsite
  assert_success
  
  # Verify directory structure
  [ -d "$test_web_root/sites/mytestsite/site/pages" ] || {
    TEST_FAILURE_REASON="pages directory not created"
    return 1
  }
  [ -d "$test_web_root/sites/mytestsite/site/uploads" ] || {
    TEST_FAILURE_REASON="uploads directory not created"
    return 1
  }
  [ -d "$test_web_root/sites/mytestsite/site/static" ] || {
    TEST_FAILURE_REASON="static directory not created"
    return 1
  }
  [ -d "$test_web_root/sites/mytestsite/build" ] || {
    TEST_FAILURE_REASON="build directory not created"
    return 1
  }
  
  # Cleanup
  rm -rf "$test_web_root"
}

run_test_case "web-create-site --help works" test_web_create_site_help
run_test_case "web-create-site creates structure" test_web_create_site_creates_structure

finish_tests
