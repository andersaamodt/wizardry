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
  
  # Stub sudo so fix-site-security doesn't create privileged directories
  stub_dir=$(temp-dir web-wizardry-stub)
  stub-sudo "$stub_dir"
  export PATH="$stub_dir:$PATH"
  
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
  rm -rf "$test_web_root" "$stub_dir"
}

test_configure_nginx_supports_onion_addresses() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Stub sudo so fix-site-security doesn't create privileged directories
  stub_dir=$(temp-dir web-wizardry-stub)
  stub-sudo "$stub_dir"
  export PATH="$stub_dir:$PATH"
  
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
  rm -rf "$test_web_root" "$stub_dir"
}

test_configure_nginx_supports_domain_aliases_from_site_conf() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-sudo "$stub_dir"
  export PATH="$stub_dir:$PATH"

  mkdir -p "$test_web_root/mytestsite"
  cat >"$test_web_root/mytestsite/site.conf" <<'EOF'
site-name=mytestsite
port=8080
domain=example.com
domain-aliases=maps.example.com www.example.com
https=false
EOF

  run_spell spells/web/configure-nginx mytestsite
  assert_success || return 1

  grep -q "server_name example.com maps.example.com www.example.com \\*.onion;" "$test_web_root/mytestsite/nginx/nginx.conf" || {
    TEST_FAILURE_REASON="nginx.conf does not include configured domain aliases"
    return 1
  }

  rm -rf "$test_web_root" "$stub_dir"
}

test_configure_nginx_preserves_existing_port() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Stub sudo so fix-site-security doesn't create privileged directories
  stub_dir=$(temp-dir web-wizardry-stub)
  stub-sudo "$stub_dir"
  export PATH="$stub_dir:$PATH"
  
  # Create a test site directory
  mkdir -p "$test_web_root/mytestsite"
  
  # Create initial site.conf with custom port
  printf 'site-name=mytestsite\nport=9090\ndomain=localhost\nhttps=false\n' > "$test_web_root/mytestsite/site.conf"
  
  # Run configure-nginx without options (simulating "Rebuild nginx.conf" from menu)
  run_spell spells/web/configure-nginx mytestsite
  assert_success
  
  # Verify port was preserved (not reset to 8080)
  actual_port=$(grep "^port=" "$test_web_root/mytestsite/site.conf" | cut -d= -f2)
  if [ "$actual_port" != "9090" ]; then
    TEST_FAILURE_REASON="configure-nginx reset port to $actual_port instead of preserving 9090"
    return 1
  fi
  
  # Verify nginx.conf uses the preserved port
  grep -q "listen 9090" "$test_web_root/mytestsite/nginx/nginx.conf" || {
    TEST_FAILURE_REASON="nginx.conf does not listen on preserved port 9090"
    return 1
  }
  
  # Cleanup
  rm -rf "$test_web_root" "$stub_dir"
}

test_configure_nginx_rejects_path_shaped_site_name() {
  skip-if-compiled || return $?

  tmpdir=$(make_tempdir)
  web_root="$tmpdir/sites"
  escape_dir="$tmpdir/escape"
  mkdir -p "$web_root" "$escape_dir"
  printf 'site-name=escape\n' > "$escape_dir/site.conf"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-sudo "$stub_dir"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" \
    run_spell spells/web/configure-nginx ../escape

  assert_failure || return 1
  assert_error_contains "invalid site name" || return 1
  if [ -d "$escape_dir/nginx" ]; then
    TEST_FAILURE_REASON="configure-nginx created nginx paths outside WEB_WIZARDRY_ROOT"
    return 1
  fi

  rm -rf "$tmpdir" "$stub_dir"
}

test_configure_nginx_rejects_imported_port_injection() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-sudo "$stub_dir"
  export PATH="$stub_dir:$PATH"

  mkdir -p "$test_web_root/mytestsite"
  cat >"$test_web_root/mytestsite/site.conf" <<'EOF'
site-name=mytestsite
port=8080;
include /tmp/evil.conf
domain=localhost
https=false
EOF

  run_spell spells/web/configure-nginx mytestsite
  assert_failure || return 1
  assert_error_contains "invalid port" || return 1
  if [ -f "$test_web_root/mytestsite/nginx/nginx.conf" ]; then
    TEST_FAILURE_REASON="configure-nginx wrote nginx.conf for invalid imported port"
    return 1
  fi

  rm -rf "$test_web_root" "$stub_dir"
}

test_configure_nginx_rejects_imported_domain_injection() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-sudo "$stub_dir"
  export PATH="$stub_dir:$PATH"

  mkdir -p "$test_web_root/mytestsite"
  cat >"$test_web_root/mytestsite/site.conf" <<'EOF'
site-name=mytestsite
port=8080
domain=example.com;
include /tmp/evil.conf
https=false
EOF

  run_spell spells/web/configure-nginx mytestsite
  assert_failure || return 1
  assert_error_contains "invalid domain" || return 1
  if [ -f "$test_web_root/mytestsite/nginx/nginx.conf" ]; then
    TEST_FAILURE_REASON="configure-nginx wrote nginx.conf for invalid imported domain"
    return 1
  fi

  rm -rf "$test_web_root" "$stub_dir"
}

test_configure_nginx_rejects_imported_domain_alias_injection() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-sudo "$stub_dir"
  export PATH="$stub_dir:$PATH"

  mkdir -p "$test_web_root/mytestsite"
  cat >"$test_web_root/mytestsite/site.conf" <<'EOF'
site-name=mytestsite
port=8080
domain=example.com
domain-aliases=maps.example.com; include /tmp/evil.conf
https=false
EOF

  run_spell spells/web/configure-nginx mytestsite
  assert_failure || return 1
  assert_error_contains "invalid domain-aliases" || return 1
  if [ -f "$test_web_root/mytestsite/nginx/nginx.conf" ]; then
    TEST_FAILURE_REASON="configure-nginx wrote nginx.conf for invalid imported domain-aliases"
    return 1
  fi

  rm -rf "$test_web_root" "$stub_dir"
}

test_configure_nginx_rejects_imported_cgi_dir_injection() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-sudo "$stub_dir"
  export PATH="$stub_dir:$PATH"

  mkdir -p "$test_web_root/mytestsite"
  cat >"$test_web_root/mytestsite/site.conf" <<'EOF'
site-name=mytestsite
port=8080
domain=localhost
cgi-dir=cgi"; include /tmp/evil.conf; #
https=false
EOF

  run_spell spells/web/configure-nginx mytestsite
  assert_failure || return 1
  assert_error_contains "invalid cgi-dir" || return 1
  if [ -f "$test_web_root/mytestsite/nginx/nginx.conf" ]; then
    TEST_FAILURE_REASON="configure-nginx wrote nginx.conf for invalid imported cgi-dir"
    return 1
  fi

  rm -rf "$test_web_root" "$stub_dir"
}

test_configure_nginx_rejects_invalid_imported_site_user() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-sudo "$stub_dir"
  export PATH="$stub_dir:$PATH"

  mkdir -p "$test_web_root/mytestsite"
  cat >"$test_web_root/mytestsite/site.conf" <<'EOF'
site-name=mytestsite
site-user=#0
port=8080
domain=localhost
https=false
EOF

  run_spell spells/web/configure-nginx mytestsite
  assert_failure || return 1
  assert_error_contains "invalid site-user" || return 1
  if [ -f "$test_web_root/mytestsite/nginx/nginx.conf" ]; then
    TEST_FAILURE_REASON="configure-nginx wrote nginx.conf for invalid imported site-user"
    return 1
  fi

  rm -rf "$test_web_root" "$stub_dir"
}

test_configure_nginx_honors_external_build_dir() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-sudo "$stub_dir"
  export PATH="$stub_dir:$PATH"

  mkdir -p "$test_web_root/mytestsite"
  cat > "$test_web_root/mytestsite/site.conf" <<EOF
site-name=mytestsite
port=8080
domain=localhost
https=false
build-dir=$test_web_root/.sitedata/mytestsite-build
EOF

  run_spell spells/web/configure-nginx mytestsite
  assert_success || return 1

  grep -q "root $test_web_root/.sitedata/mytestsite-build;" "$test_web_root/mytestsite/nginx/nginx.conf" || {
    TEST_FAILURE_REASON="configure-nginx should use configured external build-dir as nginx root"
    return 1
  }

  grep -q "alias $test_web_root/.sitedata/mytestsite-build/static/;" "$test_web_root/mytestsite/nginx/nginx.conf" || {
    TEST_FAILURE_REASON="configure-nginx should use configured external build-dir for static alias"
    return 1
  }

  rm -rf "$test_web_root" "$stub_dir"
}

test_configure_nginx_uses_xdg_runtime_for_git_workspace_roots() {
  skip-if-compiled || return $?

  tmpdir=$(make_tempdir)
  test_home="$tmpdir/home"
  test_web_root="$test_home/git"
  site_dir="$test_web_root/mytestsite"
  stub_dir=$(temp-dir web-wizardry-stub)

  mkdir -p "$site_dir/nginx"
  printf '%s\n' legacy > "$site_dir/nginx/error.log"
  stub-sudo "$stub_dir"

  status=0
  HOME="$test_home" WEB_WIZARDRY_ROOT="$test_web_root" PATH="$stub_dir:$PATH" \
    sh "$test_root/spells/web/configure-nginx" mytestsite >/dev/null 2>"$tmpdir/error" || status=$?
  [ "$status" -eq 0 ] || {
    TEST_FAILURE_REASON="configure-nginx should succeed for git workspace checkouts"
    rm -rf "$tmpdir" "$stub_dir"
    return 1
  }
  [ ! -s "$tmpdir/error" ] || {
    TEST_FAILURE_REASON="configure-nginx should not emit errors for git workspace checkouts"
    rm -rf "$tmpdir" "$stub_dir"
    return 1
  }

  runtime_dir=$(HOME="$test_home" sh "$test_root/spells/.imps/web/site-runtime-dir" "$site_dir" nginx)
  [ -f "$runtime_dir/nginx.conf" ] || {
    TEST_FAILURE_REASON="configure-nginx should write nginx.conf under the external runtime dir"
    rm -rf "$tmpdir" "$stub_dir"
    return 1
  }
  [ -f "$runtime_dir/error.log" ] || {
    TEST_FAILURE_REASON="configure-nginx should migrate legacy runtime log files into XDG state"
    rm -rf "$tmpdir" "$stub_dir"
    return 1
  }
  [ ! -e "$site_dir/nginx/nginx.conf" ] || {
    TEST_FAILURE_REASON="configure-nginx should not recreate repo-local nginx.conf for git workspaces"
    rm -rf "$tmpdir" "$stub_dir"
    return 1
  }

  grep -q "error_log $runtime_dir/error.log warn;" "$runtime_dir/nginx.conf" || {
    TEST_FAILURE_REASON="nginx.conf should point error_log at the external runtime dir"
    rm -rf "$tmpdir" "$stub_dir"
    return 1
  }
  grep -q "access_log $runtime_dir/access.log;" "$runtime_dir/nginx.conf" || {
    TEST_FAILURE_REASON="nginx.conf should point access_log at the external runtime dir"
    rm -rf "$tmpdir" "$stub_dir"
    return 1
  }

  rm -rf "$tmpdir" "$stub_dir"
}

test_configure_nginx_uses_tmpdir_for_long_socket_paths() {
  skip-if-compiled || return $?

  tmpdir=$(make_tempdir)
  runtime_dir="$tmpdir/runtime"
  test_web_root="$tmpdir/a-very-long-web-root-name-that-forces-the-fastcgi-socket-fallback"
  stub_dir=$(temp-dir web-wizardry-stub)
  mkdir -p "$runtime_dir" "$test_web_root/mytestsite"
  stub-sudo "$stub_dir"

  status=0
  PATH="$stub_dir:$PATH" TMPDIR="$runtime_dir" WEB_WIZARDRY_ROOT="$test_web_root" \
    sh "$test_root/spells/web/configure-nginx" mytestsite >/dev/null 2>&1 || status=$?
  [ "$status" -eq 0 ] || return 1
  assert_file_contains "$test_web_root/mytestsite/nginx/nginx.conf" \
    "$runtime_dir/wizardry-fcgiwrap/" || return 1
}

test_configure_nginx_routes_readable_file_links() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-wizardry-test)
  stub_dir=$(temp-dir web-wizardry-stub)
  mkdir -p "$test_web_root/mytestsite"
  stub-sudo "$stub_dir"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$test_web_root" \
    run_spell spells/web/configure-nginx mytestsite
  assert_success || return 1

  assert_file_contains "$test_web_root/mytestsite/nginx/nginx.conf" \
    'location ~ ^/file/([^/]+)(?:/.*)?$ {' || return 1
  assert_file_contains "$test_web_root/mytestsite/nginx/nginx.conf" \
    'rewrite ^/file/([^/]+)(?:/.*)?$ /cgi/blog-file?file_key=$1 last;' || return 1

  rm -rf "$test_web_root" "$stub_dir"
}

run_test_case "configure-nginx --help" test_configure_nginx_help
run_test_case "configure-nginx creates local mime.types" test_configure_nginx_creates_local_mimetypes
run_test_case "configure-nginx supports .onion addresses" test_configure_nginx_supports_onion_addresses
run_test_case "configure-nginx supports domain aliases from site.conf" \
  test_configure_nginx_supports_domain_aliases_from_site_conf
run_test_case "configure-nginx preserves existing port" test_configure_nginx_preserves_existing_port
run_test_case "configure-nginx rejects path-shaped site names" \
  test_configure_nginx_rejects_path_shaped_site_name
run_test_case "configure-nginx rejects imported port injection" \
  test_configure_nginx_rejects_imported_port_injection
run_test_case "configure-nginx rejects imported domain injection" \
  test_configure_nginx_rejects_imported_domain_injection
run_test_case "configure-nginx rejects imported domain-alias injection" \
  test_configure_nginx_rejects_imported_domain_alias_injection
run_test_case "configure-nginx rejects imported cgi-dir injection" \
  test_configure_nginx_rejects_imported_cgi_dir_injection
run_test_case "configure-nginx rejects invalid imported site-user" \
  test_configure_nginx_rejects_invalid_imported_site_user
run_test_case "configure-nginx honors external build-dir" \
  test_configure_nginx_honors_external_build_dir
run_test_case "configure-nginx uses XDG runtime dirs for git workspace sites" \
  test_configure_nginx_uses_xdg_runtime_for_git_workspace_roots
run_test_case "configure-nginx uses TMPDIR for long FastCGI socket paths" \
  test_configure_nginx_uses_tmpdir_for_long_socket_paths
run_test_case "configure-nginx routes readable file links" \
  test_configure_nginx_routes_readable_file_links

finish_tests
