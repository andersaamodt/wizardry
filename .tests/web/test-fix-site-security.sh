#!/bin/sh
# Tests for fix-site-security spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_fix_site_security_help() {
  run_spell spells/web/fix-site-security --help
  assert_success
  assert_output_contains "Usage: fix-site-security"
}

test_fix_site_security_sets_site_user() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/site" "$web_root/.sitedata/mysite"
  cat > "$site_dir/site.conf" <<EOF
# Site configuration for mysite
site-name=mysite
site-user=
EOF
  printf '%s\n' "relative/path" > "$site_dir/site.allowlist"

  stub_dir=$(temp-dir web-wizardry-stub)
  cat > "$stub_dir/sudo" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat > "$stub_dir/useradd" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat > "$stub_dir/adduser" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/sudo" "$stub_dir/useradd" "$stub_dir/adduser"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" run_spell spells/web/fix-site-security mysite
  assert_success
  assert_output_contains "Site security fixed"

  site_user=$(config-get "$site_dir/site.conf" site-user 2>/dev/null || printf '')
  if [ "$site_user" != "ww_mysite" ]; then
    TEST_FAILURE_REASON="site-user not set"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir"
}

test_fix_site_security_sitedata_writable() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  sitedata_dir="$web_root/.sitedata/mysite"
  mkdir -p "$site_dir/site" "$sitedata_dir/chatrooms/testroom"
  cat > "$site_dir/site.conf" <<EOF
# Site configuration for mysite
site-name=mysite
site-user=$(id -un)
EOF
  
  # Create a test log file
  touch "$sitedata_dir/chatrooms/testroom/.log"

  stub_dir=$(temp-dir web-wizardry-stub)
  cat > "$stub_dir/sudo" <<'EOF'
#!/bin/sh
# Pass through to real commands but skip chown since we can't create users in test
case "$1" in
  chown) exit 0 ;;
  *) exec "$@" ;;
esac
EOF
  cat > "$stub_dir/useradd" <<'EOF'
#!/bin/sh
exit 0
EOF
  stub-uname-linux "$stub_dir"
  chmod +x "$stub_dir/sudo" "$stub_dir/useradd"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" run_spell spells/web/fix-site-security mysite
  assert_success

  # Check that .sitedata files remain writable by the actual user.
  perms=$(stat -c '%a' "$sitedata_dir/chatrooms/testroom/.log" 2>/dev/null || \
          stat -f '%Lp' "$sitedata_dir/chatrooms/testroom/.log" 2>/dev/null || echo "000")

  if [ ! -w "$sitedata_dir/chatrooms/testroom/.log" ]; then
    TEST_FAILURE_REASON=".sitedata file permissions are $perms, expected owner-writable"
    rm -rf "$web_root" "$stub_dir"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir"
}

test_fix_site_security_does_not_create_site_web_lib_cache() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/site" "$web_root/.sitedata/mysite"
  cat > "$site_dir/site.conf" <<EOF
# Site configuration for mysite
site-name=mysite
site-user=ww_mysite
EOF

  stub_dir=$(temp-dir web-wizardry-stub)
  cat > "$stub_dir/sudo" <<'EOF'
#!/bin/sh
case "$1" in
  chown) exit 0 ;;
  *) exec "$@" ;;
esac
EOF
  cat > "$stub_dir/useradd" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/sudo" "$stub_dir/useradd"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" run_spell spells/web/fix-site-security mysite
  assert_success

  if [ -d "$site_dir/.web-libs" ]; then
    TEST_FAILURE_REASON="fix-site-security unexpectedly created site-local .web-libs cache"
    rm -rf "$web_root" "$stub_dir"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir"
}

test_fix_site_security_nginx_is_group_writable() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  nginx_dir="$site_dir/nginx"
  mkdir -p "$site_dir/site" "$nginx_dir"
  cat > "$site_dir/site.conf" <<EOF
# Site configuration for mysite
site-name=mysite
site-user=$(id -un)
EOF
  touch "$nginx_dir/nginx.conf"

  stub_dir=$(temp-dir web-wizardry-stub)
  cat > "$stub_dir/sudo" <<'EOF'
#!/bin/sh
# Pass through everything except chown in tests.
case "$1" in
  chown) exit 0 ;;
  *) exec "$@" ;;
esac
EOF
  cat > "$stub_dir/useradd" <<'EOF'
#!/bin/sh
exit 0
EOF
  stub-uname-linux "$stub_dir"
  chmod +x "$stub_dir/sudo" "$stub_dir/useradd"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" \
    run_spell spells/web/fix-site-security mysite
  assert_success

  dir_perms=$(stat -c '%a' "$nginx_dir" 2>/dev/null || \
    stat -f '%Lp' "$nginx_dir" 2>/dev/null || echo "000")
  file_perms=$(stat -c '%a' "$nginx_dir/nginx.conf" 2>/dev/null || \
    stat -f '%Lp' "$nginx_dir/nginx.conf" 2>/dev/null || echo "000")

  if [ "$dir_perms" != "775" ]; then
    TEST_FAILURE_REASON="nginx dir permissions are $dir_perms, expected 775"
    rm -rf "$web_root" "$stub_dir"
    return 1
  fi
  if [ "$file_perms" != "664" ]; then
    TEST_FAILURE_REASON="nginx file permissions are $file_perms, expected 664"
    rm -rf "$web_root" "$stub_dir"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir"
}

run_test_case "fix-site-security --help works" test_fix_site_security_help
run_test_case "fix-site-security sets site-user" test_fix_site_security_sets_site_user
run_test_case "fix-site-security makes sitedata files writable" test_fix_site_security_sitedata_writable
run_test_case "fix-site-security makes nginx runtime paths group-writable" \
  test_fix_site_security_nginx_is_group_writable
run_test_case "fix-site-security does not create site .web-libs cache" test_fix_site_security_does_not_create_site_web_lib_cache

finish_tests
