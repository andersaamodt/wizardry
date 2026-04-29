#!/bin/sh
# Test site-menu spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_site_menu_help() {
  run_spell spells/web/site-menu --help
  assert_success
  assert_output_contains "Usage:"
}

write_site_menu_stub() {
  tmp=$1
  name=$2
  body=$3
  cat >"$tmp/$name" <<EOF
#!/bin/sh
$body
EOF
  chmod +x "$tmp/$name"
}

test_site_menu_uses_clean_local_commands() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  sites_root=$(temp-dir wizardry-sites)
  mkdir -p "$sites_root/audit-site/site" "$sites_root/.sitedata/audit-site"
  cat >"$sites_root/audit-site/site.conf" <<'EOF'
port=8080
template=demo
site-user=ww_audit_site
EOF

  stub-menu "$tmp"
  stub-require-command "$tmp"
  write_site_menu_stub "$tmp" exit-label "printf '%s' 'Exit'"
  write_site_menu_stub "$tmp" site-status "printf '%s\n' 'stopped'"
  write_site_menu_stub "$tmp" is-tor-installed "exit 1"
  write_site_menu_stub "$tmp" check-https-status "exit 1"
  write_site_menu_stub "$tmp" is-site-daemon-enabled "exit 1"
  write_site_menu_stub "$tmp" site-autorebuild "printf '%s\n' 'enabled=no'"

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" WIZARDRY_SITES_DIR="$sites_root" \
    WEB_WIZARDRY_ROOT="$sites_root" "$ROOT_DIR/spells/web/site-menu" audit-site
  assert_success || return 1

  args=$(cat "$tmp/log")
  printf '%s' "$args" | grep -F "Build all & restart server%web-wizardry rebuild 'audit-site'" \
    >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="site-menu did not use clean rebuild command: $args"
    return 1
  }
  printf '%s' "$args" | grep -F "Open site directory%browse '$sites_root/audit-site'" \
    >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="site-menu did not use browse for site directory: $args"
    return 1
  }
  printf '%s' "$args" | grep -F "Open site data%browse '$sites_root/.sitedata/audit-site'" \
    >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="site-menu did not use browse for site data: $args"
    return 1
  }
}

test_site_menu_uses_browse_url_when_serving() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  sites_root=$(temp-dir wizardry-sites)
  mkdir -p "$sites_root/audit-site/site" "$sites_root/.sitedata/audit-site"
  cat >"$sites_root/audit-site/site.conf" <<'EOF'
port=8080
template=demo
site-user=ww_audit_site
EOF

  stub-menu "$tmp"
  stub-require-command "$tmp"
  write_site_menu_stub "$tmp" exit-label "printf '%s' 'Exit'"
  write_site_menu_stub "$tmp" site-status "printf '%s\n' 'audit-site, serving'"
  write_site_menu_stub "$tmp" is-tor-installed "exit 1"
  write_site_menu_stub "$tmp" check-https-status "exit 1"
  write_site_menu_stub "$tmp" is-site-daemon-enabled "exit 1"
  write_site_menu_stub "$tmp" site-autorebuild "printf '%s\n' 'enabled=no'"

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" WIZARDRY_SITES_DIR="$sites_root" \
    WEB_WIZARDRY_ROOT="$sites_root" "$ROOT_DIR/spells/web/site-menu" audit-site
  assert_success || return 1

  args=$(cat "$tmp/log")
  printf '%s' "$args" | grep -F "Open in browser%browse-url 'http://localhost:8080'" \
    >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="site-menu did not use browse-url when serving: $args"
    return 1
  }
  printf '%s' "$args" | grep -F "Stop server%stop-site 'audit-site'" \
    >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="site-menu did not expose stop-site while serving: $args"
    return 1
  }
}

test_site_menu_quotes_imported_paths_and_sanitizes_port() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  sites_parent=$(make_tempdir)
  sites_root="$sites_parent/sites'root"
  payload="$tmp/site-menu-port-injected"
  mkdir -p "$sites_root/audit-site/site" "$sites_root/.sitedata/audit-site"
  cat >"$sites_root/audit-site/site.conf" <<EOF
port=\$(touch "$payload")
template=demo
site-user=ww_audit_site
EOF

  stub-menu "$tmp"
  stub-require-command "$tmp"
  write_site_menu_stub "$tmp" exit-label "printf '%s' 'Exit'"
  write_site_menu_stub "$tmp" site-status "printf '%s\n' 'audit-site, serving'"
  write_site_menu_stub "$tmp" is-tor-installed "exit 1"
  write_site_menu_stub "$tmp" check-https-status "exit 1"
  write_site_menu_stub "$tmp" is-site-daemon-enabled "exit 1"
  write_site_menu_stub "$tmp" site-autorebuild "printf '%s\n' 'enabled=no'"

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" WIZARDRY_SITES_DIR="$sites_root" \
    WEB_WIZARDRY_ROOT="$sites_root" "$ROOT_DIR/spells/web/site-menu" audit-site
  assert_success || return 1

  args=$(cat "$tmp/log")
  escaped_site_dir=$(printf '%s' "$sites_root/audit-site" | sed "s/'/'\\\\''/g")
  printf '%s' "$args" | grep -F "Open site directory%browse '$escaped_site_dir'" \
    >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="site-menu did not shell-quote quote-bearing site dir: $args"
    return 1
  }
  printf '%s' "$args" | grep -F "Open in browser%browse-url 'http://localhost:8080'" \
    >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="site-menu did not fall back to safe port: $args"
    return 1
  }
  if printf '%s' "$args" | grep -F '$(touch' >/dev/null 2>&1; then
    TEST_FAILURE_REASON="site-menu rendered unsafe port command substitution: $args"
    return 1
  fi
  if [ -e "$payload" ]; then
    TEST_FAILURE_REASON="site-menu executed injected port command"
    return 1
  fi
}

test_site_menu_rejects_requirement_id_traversal() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  sites_root=$(temp-dir wizardry-sites)
  mkdir -p "$sites_root/audit-site/site" "$sites_root/.sitedata/audit-site"
  cat >"$sites_root/audit-site/site.conf" <<'EOF'
port=8080
template=demo
site-user=ww_audit_site
EOF
  cat >"$sites_root/audit-site/wizardry-server-requirements.conf" <<'EOF'
../site-menu-evil-requirement=yes
EOF
  evil_meta="$ROOT_DIR/spells/web/site-menu-evil-requirement.conf"
  cat >"$evil_meta" <<'EOF'
label=Run Evil
install_label=Run Evil
install_spell=touch SHOULD_NOT_RENDER
EOF

  stub-menu "$tmp"
  stub-require-command "$tmp"
  write_site_menu_stub "$tmp" exit-label "printf '%s' 'Exit'"
  write_site_menu_stub "$tmp" site-status "printf '%s\n' 'stopped'"
  write_site_menu_stub "$tmp" is-tor-installed "exit 1"
  write_site_menu_stub "$tmp" check-https-status "exit 1"
  write_site_menu_stub "$tmp" is-site-daemon-enabled "exit 1"
  write_site_menu_stub "$tmp" site-autorebuild "printf '%s\n' 'enabled=no'"

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" WIZARDRY_SITES_DIR="$sites_root" \
    WEB_WIZARDRY_ROOT="$sites_root" "$ROOT_DIR/spells/web/site-menu" audit-site
  status=$?
  rm -f "$evil_meta"
  [ "$status" -eq 0 ] || {
    TEST_FAILURE_REASON="site-menu failed while skipping invalid requirement id"
    return 1
  }

  args=$(cat "$tmp/log")
  if printf '%s' "$args" | grep -F 'Run Evil' >/dev/null 2>&1; then
    TEST_FAILURE_REASON="site-menu rendered traversed requirement metadata: $args"
    return 1
  fi
}

run_test_case "site-menu --help" test_site_menu_help
run_test_case "site-menu uses clean local commands" \
  test_site_menu_uses_clean_local_commands
run_test_case "site-menu uses browse-url when serving" \
  test_site_menu_uses_browse_url_when_serving
run_test_case "site-menu quotes imported paths and sanitizes port" \
  test_site_menu_quotes_imported_paths_and_sanitizes_port
run_test_case "site-menu rejects requirement id traversal" \
  test_site_menu_rejects_requirement_id_traversal

finish_tests
