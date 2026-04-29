#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/web/toggle-site-tor-hosting" ]
}

run_test_case "web/toggle-site-tor-hosting is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/web/toggle-site-tor-hosting" ]
}

run_test_case "web/toggle-site-tor-hosting has content" spell_has_content

shows_help() {
  run_spell spells/web/toggle-site-tor-hosting --help
  true
}

run_test_case "toggle-site-tor-hosting shows help" shows_help

rejects_path_shaped_site_name() {
  tmpdir=$(temp-dir toggle-site-tor-hosting-path-test)
  web_root="$tmpdir/sites"
  escape_dir="$tmpdir/escape"
  mkdir -p "$web_root" "$escape_dir"
  printf 'site-name=escape\nport=8080\n' > "$escape_dir/site.conf"

  WIZARDRY_SITES_DIR="$web_root" run_spell spells/web/toggle-site-tor-hosting ../escape
  assert_failure || return 1
  assert_error_contains "invalid site name" || return 1

  rm -rf "$tmpdir"
}

run_test_case "toggle-site-tor-hosting rejects path-shaped site names" \
  rejects_path_shaped_site_name

rejects_imported_port_injection() {
  tmpdir=$(temp-dir toggle-site-tor-hosting-port-test)
  web_root="$tmpdir/sites"
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir"
  cat >"$site_dir/site.conf" <<'EOF'
site-name=mysite
port=8080;
HiddenServiceDir /tmp/evil
EOF

  WIZARDRY_SITES_DIR="$web_root" run_spell spells/web/toggle-site-tor-hosting mysite
  assert_failure || return 1
  assert_error_contains "invalid port" || return 1

  rm -rf "$tmpdir"
}

run_test_case "toggle-site-tor-hosting rejects imported port injection" \
  rejects_imported_port_injection

does_not_treat_site_name_as_regex() {
  tmpdir=$(temp-dir toggle-site-tor-hosting-regex-test)
  web_root="$tmpdir/sites"
  site_dir="$web_root/a.b"
  tor_data="$tmpdir/tor-data"
  torrc="$tmpdir/torrc"
  stub_dir="$tmpdir/stubs"
  mkdir -p "$site_dir" "$tor_data/axb" "$stub_dir"
  printf 'site-name=a.b\nport=8080\n' > "$site_dir/site.conf"
  cat >"$torrc" <<EOF
DataDirectory $tor_data
HiddenServiceDir $tor_data/axb
HiddenServiceVersion 3
HiddenServicePort 80 127.0.0.1:8080
EOF

  stub-sudo "$stub_dir"
  cat >"$stub_dir/torrc-path" <<EOF
#!/bin/sh
printf '%s\n' '$torrc'
EOF
  cat >"$stub_dir/is-tor-installed" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat >"$stub_dir/is-tor-daemon-enabled" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat >"$stub_dir/is-tor-running" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat >"$stub_dir/detect-distro" <<'EOF'
#!/bin/sh
printf '%s\n' linux
EOF
  cat >"$stub_dir/repair-tor-permissions" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat >"$stub_dir/restart-tor" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/torrc-path" "$stub_dir/is-tor-installed" \
    "$stub_dir/is-tor-daemon-enabled" "$stub_dir/is-tor-running" \
    "$stub_dir/detect-distro" "$stub_dir/repair-tor-permissions" \
    "$stub_dir/restart-tor"

  PATH="$stub_dir:$PATH" WIZARDRY_SITES_DIR="$web_root" \
    run_spell spells/web/toggle-site-tor-hosting a.b
  assert_success || return 1

  if ! grep -F "HiddenServiceDir $tor_data/axb" "$torrc" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="regex-like site name removed sibling axb hidden service"
    return 1
  fi
  if ! grep -F "HiddenServiceDir $tor_data/a.b/" "$torrc" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="toggle-site-tor-hosting did not add exact a.b hidden service"
    return 1
  fi

  rm -rf "$tmpdir"
}

run_test_case "toggle-site-tor-hosting treats dotted site names literally" \
  does_not_treat_site_name_as_regex
finish_tests
