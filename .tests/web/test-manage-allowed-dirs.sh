#!/bin/sh
# Tests for manage-allowed-dirs spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_manage_allowed_dirs_help() {
  run_spell spells/web/manage-allowed-dirs --help
  assert_success
  assert_output_contains "Usage: manage-allowed-dirs"
}

test_manage_allowed_dirs_adds_entry() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/site"
  current_user=$(id -un)
  cat > "$site_dir/site.conf" <<EOF
# Site configuration for mysite
site-name=mysite
site-user=$current_user
EOF

  allow_dir=$(temp-dir web-wizardry-allow)

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-menu "$stub_dir"
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

  menu_log="$stub_dir/menu.log"
  run_cmd env PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" MENU_LOG="$menu_log" \
    sh -c "printf 'y\n%s\n' '$allow_dir' | '$ROOT_DIR/spells/web/manage-allowed-dirs' mysite"
  assert_success

  if ! grep -Fx "$allow_dir" "$site_dir/site.allowlist" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="allowlist entry not added"
    return 1
  fi

  if [ ! -f "$menu_log" ]; then
    TEST_FAILURE_REASON="menu log not created"
    return 1
  fi
  if ! grep -F "Add allowed dir" "$menu_log" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="menu did not include add option"
    return 1
  fi
  if ! grep -F "$allow_dir" "$menu_log" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="menu did not include allowlist entry"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$allow_dir"
}

test_manage_allowed_dirs_rejects_path_shaped_site_name() {
  skip-if-compiled || return $?

  tmpdir=$(make_tempdir)
  web_root="$tmpdir/sites"
  escape_dir="$tmpdir/escape"
  mkdir -p "$web_root" "$escape_dir"
  current_user=$(id -un)
  cat > "$escape_dir/site.conf" <<EOF
site-name=escape
site-user=$current_user
EOF

  WEB_WIZARDRY_ROOT="$web_root" run_spell spells/web/manage-allowed-dirs ../escape

  assert_failure || return 1
  assert_error_contains "invalid site name" || return 1
  if [ -e "$escape_dir/site.allowlist" ]; then
    TEST_FAILURE_REASON="manage-allowed-dirs wrote an allowlist outside the web root"
    return 1
  fi
}

test_manage_allowed_dirs_shell_quotes_menu_paths() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/site"
  current_user=$(id -un)
  cat > "$site_dir/site.conf" <<EOF
site-name=mysite
site-user=$current_user
EOF

  allow_parent=$(temp-dir web-wizardry-allow)
  allow_dir="$allow_parent/quote ' dir"
  mkdir -p "$allow_dir"
  printf '%s\n' "$allow_dir" > "$site_dir/site.allowlist"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-menu "$stub_dir"
  menu_log="$stub_dir/menu.log"

  run_cmd env PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" MENU_LOG="$menu_log" \
    "$ROOT_DIR/spells/web/manage-allowed-dirs" mysite
  assert_success

  escaped_allow_dir=$(printf '%s' "$allow_dir" | sed "s/'/'\\\\''/g")
  expected_action="remove_allowlist_entry '$escaped_allow_dir'"
  if ! grep -F "$expected_action" "$menu_log" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="menu action did not shell-quote quote-bearing allowlist path"
    rm -rf "$web_root" "$stub_dir" "$allow_parent"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$allow_parent"
}

test_manage_allowed_dirs_rejects_broad_paths() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/site"
  current_user=$(id -un)
  cat > "$site_dir/site.conf" <<EOF
site-name=mysite
site-user=$current_user
EOF

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-menu "$stub_dir"

  run_cmd env PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" MENU_LOG="$stub_dir/menu.log" \
    sh -c "printf 'y\n%s\nn\n' '$web_root' | '$ROOT_DIR/spells/web/manage-allowed-dirs' mysite"
  assert_success

  if grep -Fx "$web_root" "$site_dir/site.allowlist" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="manage-allowed-dirs allowed broad web root path"
    rm -rf "$web_root" "$stub_dir"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir"
}

run_test_case "manage-allowed-dirs --help works" test_manage_allowed_dirs_help
run_test_case "manage-allowed-dirs adds allowlist entry" test_manage_allowed_dirs_adds_entry
run_test_case "manage-allowed-dirs rejects path-shaped site names" test_manage_allowed_dirs_rejects_path_shaped_site_name
run_test_case "manage-allowed-dirs shell-quotes menu paths" \
  test_manage_allowed_dirs_shell_quotes_menu_paths
run_test_case "manage-allowed-dirs rejects broad paths" \
  test_manage_allowed_dirs_rejects_broad_paths

finish_tests
