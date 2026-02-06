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

run_test_case "manage-allowed-dirs --help works" test_manage_allowed_dirs_help
run_test_case "manage-allowed-dirs adds allowlist entry" test_manage_allowed_dirs_adds_entry

finish_tests
