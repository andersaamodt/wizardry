#!/bin/sh
# Integration test for serve-site and CGI functionality

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_site_serving_and_cgi() {
  skip-if-compiled || return $?
  
  # Check if required tools are available
  if ! command -v nginx >/dev/null 2>&1; then
    TEST_SKIP_REASON="nginx not installed"
    exit 222
  fi
  
  if ! command -v fcgiwrap >/dev/null 2>&1; then
    TEST_SKIP_REASON="fcgiwrap not installed"
    exit 222
  fi
  
  if ! command -v pandoc >/dev/null 2>&1; then
    TEST_SKIP_REASON="pandoc not installed"
    exit 222
  fi
  
  if ! command -v curl >/dev/null 2>&1; then
    TEST_SKIP_REASON="curl not installed"
    exit 222
  fi
  
  # Set up test environment
  test_web_root=$(temp-dir web-integration-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  serve_output="$test_web_root/serve_output.txt"
  
  # Ensure cleanup happens on exit
  cleanup_test() {
    # Stop any running site
    run_spell spells/web/stop-site testsite >/dev/null 2>&1 || true
    # Clean up temp directory
    rm -rf "$test_web_root"
  }
  trap cleanup_test EXIT
  
  # Create a test site
  run_spell spells/web/create-site testsite >/dev/null 2>&1
  assert_success
  
  # Create a simple test page with htmx
  cat > "$test_web_root/testsite/site/pages/test.md" <<'TESTPAGE'
---
title: Test Page
---

# Test Page

<button hx-get="/cgi/example-cgi" hx-target="#result">Test CGI</button>
<div id="result"></div>
TESTPAGE
  
  # Build the site
  run_spell spells/web/build testsite >/dev/null 2>&1
  assert_success
  
  # Verify build output exists
  [ -f "$test_web_root/testsite/build/pages/index.html" ] || {
    TEST_FAILURE_REASON="Build did not create index.html"
    return 1
  }
  
  # Verify htmx is included in built HTML
  if ! grep -q "htmx.org" "$test_web_root/testsite/build/pages/test.html" 2>/dev/null; then
    TEST_FAILURE_REASON="htmx script not included in generated HTML"
    return 1
  fi
  
  # Start serving the site in background
  # We need to capture the output to know when it's ready
  run_spell spells/web/serve-site testsite >"$serve_output" 2>&1 &
  serve_pid=$!
  
  # Wait for site to start (max 10 seconds)
  max_wait=10
  waited=0
  site_ready=0
  
  while [ $waited -lt $max_wait ]; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null | grep -q "200\|301\|302"; then
      site_ready=1
      break
    fi
    sleep 1
    waited=$((waited + 1))
  done
  
  if [ $site_ready -eq 0 ]; then
    # Site didn't start - capture logs
    cat "$serve_output" 2>/dev/null || true
    TEST_FAILURE_REASON="Site failed to start within ${max_wait}s"
    return 1
  fi
  
  # Test 1: Verify homepage is accessible
  http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/pages/index.html 2>/dev/null)
  if [ "$http_code" != "200" ]; then
    TEST_FAILURE_REASON="Homepage returned $http_code instead of 200"
    return 1
  fi
  
  # Test 2: Verify CGI endpoint is accessible
  cgi_response=$(curl -s http://localhost:8080/cgi/example-cgi 2>/dev/null)
  cgi_exit=$?
  
  if [ $cgi_exit -ne 0 ]; then
    TEST_FAILURE_REASON="Failed to connect to CGI endpoint"
    return 1
  fi
  
  # Test 3: Verify CGI response contains expected content
  if ! printf '%s' "$cgi_response" | grep -q "Hello from CGI"; then
    TEST_FAILURE_REASON="CGI response did not contain expected content"
    return 1
  fi
  
  # Test 4: Verify CGI response is valid HTML
  if ! printf '%s' "$cgi_response" | grep -q "<html>"; then
    TEST_FAILURE_REASON="CGI response is not valid HTML"
    return 1
  fi
  
  # Clean up: stop the site
  run_spell spells/web/stop-site testsite >/dev/null 2>&1
  
  # Wait a moment for cleanup
  sleep 1
  
  # Verify site stopped
  if curl -s -o /dev/null http://localhost:8080/ 2>/dev/null; then
    TEST_FAILURE_REASON="Site still responding after stop-site"
    return 1
  fi
  
  # Trap will handle final cleanup
}

run_test_case "site serving and CGI integration" test_site_serving_and_cgi

finish_tests
