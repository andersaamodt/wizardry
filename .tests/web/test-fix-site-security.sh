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

run_test_case "fix-site-security --help works" test_fix_site_security_help
run_test_case "fix-site-security sets site-user" test_fix_site_security_sets_site_user

finish_tests
