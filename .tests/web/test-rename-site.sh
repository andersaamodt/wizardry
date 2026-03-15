#!/bin/sh
# Test rename-site spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_rename_site_help() {
  run_spell spells/web/rename-site --help
  assert_success
  assert_output_contains "Usage:"
}

test_rename_site_requires_old_name() {
  skip-if-compiled || return $?
  run_spell spells/web/rename-site
  assert_status 2
  assert_error_contains "OLD_NAME required"
}

test_rename_site_moves_site_and_data() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir rename-site-test)
  stub_dir=$(temp-dir rename-site-stubs)
  export WIZARDRY_SITES_DIR="$test_web_root"
  export SERVICE_DIR="$test_web_root/services"
  mkdir -p "$SERVICE_DIR"
  mkdir -p "$test_web_root/oldsite/site/pages"
  mkdir -p "$test_web_root/oldsite/nginx"
  mkdir -p "$test_web_root/.sitedata/oldsite"
  printf 'site-name=oldsite\nport=8080\ndomain=localhost\nhttps=false\n' > "$test_web_root/oldsite/site.conf"
  printf 'payload\n' > "$test_web_root/.sitedata/oldsite/data.txt"

  cat > "$stub_dir/configure-nginx" <<'EOF'
#!/bin/sh
set -eu
site_name=${1-}
printf '%s\n' "$site_name" > "${WIZARDRY_SITES_DIR}/.${site_name}.configure-nginx"
EOF
  chmod +x "$stub_dir/configure-nginx"

  cat > "$stub_dir/fix-site-security" <<'EOF'
#!/bin/sh
set -eu
site_name=${1-}
printf '%s\n' "$site_name" > "${WIZARDRY_SITES_DIR}/.${site_name}.fix-site-security"
EOF
  chmod +x "$stub_dir/fix-site-security"

  PATH="$stub_dir:$PATH"
  export PATH

  run_spell spells/web/rename-site oldsite newsite
  assert_success
  assert_output_contains "Change: moving site directory"
  assert_output_contains "Change: moving site data directory"
  assert_output_contains "Change: updating site-name in config"

  assert_path_exists "$test_web_root/newsite"
  if [ -e "$test_web_root/oldsite" ]; then
    fail "old site directory still exists"
    return 1
  fi
  assert_path_exists "$test_web_root/.sitedata/newsite"
  if [ -e "$test_web_root/.sitedata/oldsite" ]; then
    fail "old site data directory still exists"
    return 1
  fi
  assert_file_contains "$test_web_root/newsite/site.conf" "site-name=newsite"
  assert_path_exists "$test_web_root/.newsite.configure-nginx"
  assert_path_exists "$test_web_root/.newsite.fix-site-security"

  rm -rf "$stub_dir" "$test_web_root"
}

run_test_case "rename-site --help" test_rename_site_help
run_test_case "rename-site requires OLD_NAME" test_rename_site_requires_old_name
run_test_case "rename-site moves site and data" test_rename_site_moves_site_and_data

finish_tests
