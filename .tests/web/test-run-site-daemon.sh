#!/bin/sh
# Tests for run-site-daemon spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_run_site_daemon_help() {
  run_spell spells/web/run-site-daemon --help
  assert_success
  assert_output_contains "Usage: run-site-daemon"
}

test_run_site_daemon_uses_wizardry_sites_dir_env() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  home_root=$(temp-dir web-wizardry-home)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/nginx"

  stub_dir=$(temp-dir web-wizardry-stub)
  cat > "$stub_dir/nginx" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/nginx"

  # WEB_WIZARDRY_ROOT is intentionally unset here to emulate launchd/systemd
  # environments where only WIZARDRY_SITES_DIR is provided.
  PATH="$stub_dir:$PATH" HOME="$home_root" WIZARDRY_SITES_DIR="$web_root" \
    run_spell spells/web/run-site-daemon mysite

  # If run-site-daemon ignores WIZARDRY_SITES_DIR, it fails with "site not found".
  # Correct behavior reaches the nginx.conf prerequisite check.
  assert_status 1
  assert_error_contains "nginx.conf missing"

  rm -rf "$web_root" "$home_root" "$stub_dir"
}

test_run_site_daemon_uses_nginx_bin_fallback() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/nginx"

  stub_dir=$(temp-dir web-wizardry-stub)
  cat > "$stub_dir/nginx-fallback" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/nginx-fallback"

  # No nginx in PATH; spell should still proceed by using WIZARDRY_NGINX_BIN.
  PATH="/usr/bin:/bin" WEB_WIZARDRY_ROOT="$web_root" \
    WIZARDRY_NGINX_BIN="$stub_dir/nginx-fallback" \
    run_spell spells/web/run-site-daemon mysite

  assert_status 1
  assert_error_contains "nginx.conf missing"

  rm -rf "$web_root" "$stub_dir"
}

run_test_case "run-site-daemon --help works" test_run_site_daemon_help
run_test_case "run-site-daemon honors WIZARDRY_SITES_DIR when WEB_WIZARDRY_ROOT is unset" \
  test_run_site_daemon_uses_wizardry_sites_dir_env
run_test_case "run-site-daemon resolves nginx via absolute fallback when PATH lacks nginx" \
  test_run_site_daemon_uses_nginx_bin_fallback

finish_tests
