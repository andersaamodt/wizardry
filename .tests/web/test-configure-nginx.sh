#!/bin/sh
# Test configure-nginx spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_configure_nginx_help() {
  run_spell spells/web/configure-nginx --help
  assert_success
  assert_output_contains "Usage:"
}

test_configure_nginx_creates_local_mimetypes() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Create a test site directory
  mkdir -p "$test_web_root/mytestsite"
  
  # Run configure-nginx
  run_spell spells/web/configure-nginx mytestsite
  assert_success
  
  # Verify mime.types was created
  [ -f "$test_web_root/mytestsite/nginx/mime.types" ] || {
    TEST_FAILURE_REASON="mime.types not created"
    return 1
  }
  
  # Verify temp directories were created
  [ -d "$test_web_root/mytestsite/nginx/temp/client_body" ] || {
    TEST_FAILURE_REASON="client_body temp directory not created"
    return 1
  }
  [ -d "$test_web_root/mytestsite/nginx/temp/proxy" ] || {
    TEST_FAILURE_REASON="proxy temp directory not created"
    return 1
  }
  [ -d "$test_web_root/mytestsite/nginx/temp/fastcgi" ] || {
    TEST_FAILURE_REASON="fastcgi temp directory not created"
    return 1
  }
  [ -d "$test_web_root/mytestsite/nginx/temp/uwsgi" ] || {
    TEST_FAILURE_REASON="uwsgi temp directory not created"
    return 1
  }
  [ -d "$test_web_root/mytestsite/nginx/temp/scgi" ] || {
    TEST_FAILURE_REASON="scgi temp directory not created"
    return 1
  }
  
  # Verify nginx.conf references local mime.types
  grep -q "include $test_web_root/mytestsite/nginx/mime.types" "$test_web_root/mytestsite/nginx/nginx.conf" || {
    TEST_FAILURE_REASON="nginx.conf does not reference local mime.types"
    return 1
  }
  
  # Verify nginx.conf does not reference /etc/nginx/mime.types
  if grep -q "include /etc/nginx/mime.types" "$test_web_root/mytestsite/nginx/nginx.conf"; then
    TEST_FAILURE_REASON="nginx.conf still references system mime.types"
    return 1
  fi
  
  # Verify nginx.conf uses local temp paths
  grep -q "client_body_temp_path.*nginx/temp/client_body" "$test_web_root/mytestsite/nginx/nginx.conf" || {
    TEST_FAILURE_REASON="nginx.conf does not use local client_body_temp_path"
    return 1
  }
  grep -q "proxy_temp_path.*nginx/temp/proxy" "$test_web_root/mytestsite/nginx/nginx.conf" || {
    TEST_FAILURE_REASON="nginx.conf does not use local proxy_temp_path"
    return 1
  }
  grep -q "fastcgi_temp_path.*nginx/temp/fastcgi" "$test_web_root/mytestsite/nginx/nginx.conf" || {
    TEST_FAILURE_REASON="nginx.conf does not use local fastcgi_temp_path"
    return 1
  }
  grep -q "uwsgi_temp_path.*nginx/temp/uwsgi" "$test_web_root/mytestsite/nginx/nginx.conf" || {
    TEST_FAILURE_REASON="nginx.conf does not use local uwsgi_temp_path"
    return 1
  }
  grep -q "scgi_temp_path.*nginx/temp/scgi" "$test_web_root/mytestsite/nginx/nginx.conf" || {
    TEST_FAILURE_REASON="nginx.conf does not use local scgi_temp_path"
    return 1
  }
  
  # Cleanup
  rm -rf "$test_web_root"
}

test_configure_nginx_supports_onion_addresses() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Create a test site directory
  mkdir -p "$test_web_root/mytestsite"
  
  # Run configure-nginx
  run_spell spells/web/configure-nginx mytestsite
  assert_success
  
  # Verify nginx.conf includes *.onion in server_name for Tor support
  grep -q "server_name.*\*.onion" "$test_web_root/mytestsite/nginx/nginx.conf" || {
    TEST_FAILURE_REASON="nginx.conf does not include *.onion in server_name (needed for Tor hidden services)"
    return 1
  }
  
  # Cleanup
  rm -rf "$test_web_root"
}

run_test_case "configure-nginx --help" test_configure_nginx_help
run_test_case "configure-nginx creates local mime.types" test_configure_nginx_creates_local_mimetypes
run_test_case "configure-nginx supports .onion addresses" test_configure_nginx_supports_onion_addresses

finish_tests
