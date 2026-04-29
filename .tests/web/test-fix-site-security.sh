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

write_fix_security_identity_stubs() {
  stub_dir=$1
  stub_site_user=$2

  cat > "$stub_dir/id" <<EOF
#!/bin/sh
if [ "\${1-}" = "-u" ]; then
  if [ "\$#" -eq 1 ]; then
    printf '%s\n' '0'
    exit 0
  fi
  if [ "\${2-}" = "$stub_site_user" ]; then
    printf '%s\n' '1001'
    exit 0
  fi
fi
if [ "\${1-}" = "-un" ]; then
  printf '%s\n' 'builder'
  exit 0
fi
if [ "\${1-}" = "-gn" ] && [ "\${2-}" = "$stub_site_user" ]; then
  printf '%s\n' "$stub_site_user"
  exit 0
fi
exec /usr/bin/id "\$@"
EOF

  cat > "$stub_dir/getent" <<EOF
#!/bin/sh
if [ "\${1-}" = "group" ] && [ "\${2-}" = "$stub_site_user" ]; then
  printf '%s\n' '$stub_site_user:x:1001:'
  exit 0
fi
exit 2
EOF

  ln -sf /usr/bin/true "$stub_dir/chown"
  chmod +x "$stub_dir/id" "$stub_dir/getent"
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

test_fix_site_security_repairs_missing_linux_private_group() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/site" "$web_root/.sitedata/mysite"
  cat > "$site_dir/site.conf" <<EOF
# Site configuration for mysite
site-name=mysite
site-user=
EOF

  stub_dir=$(temp-dir web-wizardry-stub)
  state_dir=$(temp-dir web-wizardry-state)

  cat > "$stub_dir/sudo" <<'EOF'
#!/bin/sh
case "$1" in
  chown) exit 0 ;;
esac
exec "$@"
EOF
  cat > "$stub_dir/useradd" <<'EOF'
#!/bin/sh
state_dir=${TEST_STATE_DIR:?}
case "${1-}" in
  --help|-h)
    printf '%s\n' 'usage: useradd [-m] [-s shell] login'
    exit 0
    ;;
esac
  printf '%s\n' "$*" >> "$state_dir/useradd.log"
  : > "$state_dir/user.created"
  exit 0
EOF
  cat > "$stub_dir/groupadd" <<'EOF'
#!/bin/sh
state_dir=${TEST_STATE_DIR:?}
printf '%s\n' "$*" >> "$state_dir/groupadd.log"
: > "$state_dir/group.created"
exit 0
EOF
  cat > "$stub_dir/usermod" <<'EOF'
#!/bin/sh
state_dir=${TEST_STATE_DIR:?}
printf '%s\n' "$*" >> "$state_dir/usermod.log"
: > "$state_dir/group.assigned"
exit 0
EOF
  cat > "$stub_dir/getent" <<'EOF'
#!/bin/sh
state_dir=${TEST_STATE_DIR:?}
if [ "${1-}" = "group" ] && [ "${2-}" = "ww_mysite" ]; then
  if [ -f "$state_dir/group.created" ]; then
    printf '%s\n' 'ww_mysite:x:1001:'
    exit 0
  fi
  exit 2
fi
exit 2
EOF
  cat > "$stub_dir/id" <<'EOF'
#!/bin/sh
state_dir=${TEST_STATE_DIR:?}
if [ "${1-}" = "-u" ] && [ "${2-}" = "ww_mysite" ]; then
  if [ -f "$state_dir/user.created" ]; then
    printf '%s\n' '1001'
    exit 0
  fi
  exit 1
fi
if [ "${1-}" = "-gn" ] && [ "${2-}" = "ww_mysite" ]; then
  if [ -f "$state_dir/group.assigned" ]; then
    printf '%s\n' 'ww_mysite'
  else
    printf '%s\n' 'nogroup'
  fi
  exit 0
fi
if [ "${1-}" = "-un" ]; then
  printf '%s\n' 'builder'
  exit 0
fi
exec /usr/bin/id "$@"
EOF
  chmod +x "$stub_dir/sudo" "$stub_dir/useradd" "$stub_dir/groupadd" \
    "$stub_dir/usermod" "$stub_dir/getent" "$stub_dir/id"
  stub-uname-linux "$stub_dir"

  PATH="$stub_dir:$PATH" TEST_STATE_DIR="$state_dir" WEB_WIZARDRY_ROOT="$web_root" \
    run_spell spells/web/fix-site-security mysite
  assert_success

  if [ ! -f "$state_dir/groupadd.log" ]; then
    TEST_FAILURE_REASON="groupadd was not called for missing site group"
    rm -rf "$web_root" "$stub_dir" "$state_dir"
    return 1
  fi
  if ! grep -q '^ww_mysite$' "$state_dir/groupadd.log"; then
    TEST_FAILURE_REASON="groupadd did not create the expected site group"
    rm -rf "$web_root" "$stub_dir" "$state_dir"
    return 1
  fi
  if [ ! -f "$state_dir/usermod.log" ]; then
    TEST_FAILURE_REASON="usermod was not called to assign the site primary group"
    rm -rf "$web_root" "$stub_dir" "$state_dir"
    return 1
  fi
  if ! grep -q '^-g ww_mysite ww_mysite$' "$state_dir/usermod.log"; then
    TEST_FAILURE_REASON="usermod did not assign the expected primary group"
    rm -rf "$web_root" "$stub_dir" "$state_dir"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$state_dir"
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
  write_fix_security_identity_stubs "$stub_dir" "$(id -un)"
  stub-uname-linux "$stub_dir"

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
  write_fix_security_identity_stubs "$stub_dir" "ww_mysite"
  stub-uname-linux "$stub_dir"

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
  write_fix_security_identity_stubs "$stub_dir" "$(id -un)"
  stub-uname-linux "$stub_dir"

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

test_fix_site_security_rejects_path_shaped_site_name() {
  skip-if-compiled || return $?

  tmpdir=$(make_tempdir)
  web_root="$tmpdir/sites"
  escape_dir="$tmpdir/escape"
  mkdir -p "$web_root" "$escape_dir/site"
  cat > "$escape_dir/site.conf" <<'EOF'
site-user=ww_escape
EOF

  stub_dir=$(temp-dir web-wizardry-stub)
  write_fix_security_identity_stubs "$stub_dir" "ww_escape"
  stub-uname-linux "$stub_dir"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" \
    run_spell spells/web/fix-site-security ../escape

  assert_failure || return 1
  assert_error_contains "invalid site name" || return 1
  if [ -d "$escape_dir/build" ] || [ -d "$escape_dir/nginx" ]; then
    TEST_FAILURE_REASON="fix-site-security created runtime paths outside WEB_WIZARDRY_ROOT"
    return 1
  fi

  rm -rf "$tmpdir" "$stub_dir"
}

test_fix_site_security_rejects_invalid_imported_site_user() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/site" "$web_root/.sitedata/mysite"
  cat > "$site_dir/site.conf" <<'EOF'
site-name=mysite
site-user=bad;name
EOF

  WEB_WIZARDRY_ROOT="$web_root" run_spell spells/web/fix-site-security mysite

  assert_failure || return 1
  assert_error_contains "invalid site-user" || return 1

  rm -rf "$web_root"
}

test_fix_site_security_skips_broad_allowlist_dirs() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  safe_dir=$(temp-dir web-wizardry-allow)
  state_dir=$(temp-dir web-wizardry-state)
  mkdir -p "$site_dir/site" "$web_root/.sitedata/mysite"
  cat > "$site_dir/site.conf" <<'EOF'
site-name=mysite
site-user=ww_mysite
EOF
  cat > "$site_dir/site.allowlist" <<EOF
$web_root
$site_dir/site
$web_root/.sitedata
$safe_dir
EOF

  stub_dir=$(temp-dir web-wizardry-stub)
  write_fix_security_identity_stubs "$stub_dir" "ww_mysite"
  rm -f "$stub_dir/chown"
  cat > "$stub_dir/chown" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$TEST_STATE_DIR/chown.log"
exit 0
EOF
  cat > "$stub_dir/chmod" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/chown" "$stub_dir/chmod"
  stub-uname-linux "$stub_dir"

  PATH="$stub_dir:$PATH" TEST_STATE_DIR="$state_dir" WEB_WIZARDRY_ROOT="$web_root" \
    run_spell spells/web/fix-site-security mysite
  assert_success

  if ! grep -F -- "-R ww_mysite:ww_mysite $safe_dir" "$state_dir/chown.log" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="safe allowlist directory was not repaired"
    rm -rf "$web_root" "$stub_dir" "$safe_dir" "$state_dir"
    return 1
  fi
  if grep -F -- "-R ww_mysite:ww_mysite $web_root" "$state_dir/chown.log" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="broad web root was recursively chowned from allowlist"
    rm -rf "$web_root" "$stub_dir" "$safe_dir" "$state_dir"
    return 1
  fi
  if grep -F -- "-R ww_mysite:ww_mysite $site_dir/site" "$state_dir/chown.log" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="managed site source dir was recursively chowned from allowlist"
    rm -rf "$web_root" "$stub_dir" "$safe_dir" "$state_dir"
    return 1
  fi
  if grep -F -- "-R ww_mysite:ww_mysite $web_root/.sitedata" "$state_dir/chown.log" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="managed .sitedata root was recursively chowned from allowlist"
    rm -rf "$web_root" "$stub_dir" "$safe_dir" "$state_dir"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$safe_dir" "$state_dir"
}

run_test_case "fix-site-security --help works" test_fix_site_security_help
run_test_case "fix-site-security sets site-user" test_fix_site_security_sets_site_user
run_test_case "fix-site-security repairs missing Linux private groups" \
  test_fix_site_security_repairs_missing_linux_private_group
run_test_case "fix-site-security makes sitedata files writable" test_fix_site_security_sitedata_writable
run_test_case "fix-site-security makes nginx runtime paths group-writable" \
  test_fix_site_security_nginx_is_group_writable
run_test_case "fix-site-security does not create site .web-libs cache" test_fix_site_security_does_not_create_site_web_lib_cache
run_test_case "fix-site-security rejects path-shaped site names" \
  test_fix_site_security_rejects_path_shaped_site_name
run_test_case "fix-site-security rejects invalid imported site-user" \
  test_fix_site_security_rejects_invalid_imported_site_user
run_test_case "fix-site-security skips broad allowlist directories" \
  test_fix_site_security_skips_broad_allowlist_dirs

finish_tests
