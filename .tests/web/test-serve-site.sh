#!/bin/sh
# Test serve-site spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_serve_site_help() {
  run_spell spells/web/serve-site --help
  assert_success
  assert_output_contains "Usage:"
}

test_serve_site_regenerates_old_config() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Create a test site with old-style nginx.conf
  mkdir -p "$test_web_root/testsite/nginx"
  mkdir -p "$test_web_root/testsite/build/pages"
  
  # Create a dummy index.html so serve-site doesn't try to build
  printf '%s\n' "<html><body>test</body></html>" > "$test_web_root/testsite/build/pages/index.html"
  
  # Create old-style nginx.conf with /etc/nginx/mime.types
  cat > "$test_web_root/testsite/nginx/nginx.conf" << 'OLDCONF'
# nginx configuration
worker_processes 1;
daemon off;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
}
OLDCONF
  
  # Verify old config exists
  grep -q "include /etc/nginx/mime.types" "$test_web_root/testsite/nginx/nginx.conf" || {
    TEST_FAILURE_REASON="Old config not set up correctly"
    return 1
  }
  
  # Create site.conf for the test
  printf '%s\n' "port=8080" > "$test_web_root/testsite/site.conf"
  printf '%s\n' "domain=localhost" >> "$test_web_root/testsite/site.conf"
  
  # Try to serve the site (will fail because nginx not installed, but should regenerate config)
  # We just want to check if configure-nginx gets called
  run_spell spells/web/serve-site testsite 2>&1 || true
  
  # Check if config was regenerated - it should now have local path
  if grep -q "include /etc/nginx/mime.types" "$test_web_root/testsite/nginx/nginx.conf" 2>/dev/null; then
    TEST_FAILURE_REASON="Old config was not regenerated"
    return 1
  fi
  
  # Verify new config uses local path (if it was regenerated)
  if [ -f "$test_web_root/testsite/nginx/nginx.conf" ]; then
    grep -q "include.*nginx/mime.types" "$test_web_root/testsite/nginx/nginx.conf" || {
      TEST_FAILURE_REASON="New config doesn't use local mime.types path"
      return 1
    }
  fi
  
  # Cleanup
  rm -rf "$test_web_root"
}

run_test_case "serve-site --help" test_serve_site_help
run_test_case "serve-site regenerates old nginx.conf" test_serve_site_regenerates_old_config

finish_tests
