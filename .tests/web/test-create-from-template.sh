#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell spells/web/create-from-template --help
  assert_success
  assert_output_contains "Usage:"
  assert_output_contains "blog"
}

test_blog_template_creates_structure() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Create a test blog site
  run_spell spells/web/create-from-template mytestblog blog
  assert_success
  
  # Verify directory structure
  [ -d "$test_web_root/mytestblog/site/pages" ] || {
    TEST_FAILURE_REASON="pages directory not created"
    return 1
  }
  [ -d "$test_web_root/mytestblog/site/pages/posts" ] || {
    TEST_FAILURE_REASON="posts directory not created"
    return 1
  }
  [ -d "$test_web_root/mytestblog/site/static" ] || {
    TEST_FAILURE_REASON="static directory not created"
    return 1
  }
  [ -f "$test_web_root/mytestblog/site/pages/about.md" ] || {
    TEST_FAILURE_REASON="about.md not created"
    return 1
  }
  [ -f "$test_web_root/mytestblog/site/pages/index.md" ] || {
    TEST_FAILURE_REASON="index.md not created"
    return 1
  }
  [ -f "$test_web_root/mytestblog/site/static/style.css" ] || {
    TEST_FAILURE_REASON="style.css not created"
    return 1
  }
  
  # Cleanup
  rm -rf "$test_web_root"
}

test_blog_template_has_sample_posts() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Create a test blog site
  run_spell spells/web/create-from-template mytestblog blog
  assert_success
  
  # Check for sample posts
  post_count=$(find "$test_web_root/mytestblog/site/pages/posts" -name "*.md" -type f | wc -l)
  [ "$post_count" -gt 0 ] || {
    TEST_FAILURE_REASON="no sample posts found (expected at least 1)"
    return 1
  }
  
  # Cleanup
  rm -rf "$test_web_root"
}

run_test_case "create-from-template shows help" test_help
run_test_case "blog template creates structure" test_blog_template_creates_structure
run_test_case "blog template has sample posts" test_blog_template_has_sample_posts

finish_tests
