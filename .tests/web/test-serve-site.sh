#!/bin/sh
# Test serve-site spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_serve_site_help() {
  run_spell spells/web/serve-site --help
  assert_success
  assert_output_contains "Usage:"
}

test_serve_site_ignores_stale_non_nginx_pid() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/nginx"
  touch "$site_dir/nginx/nginx.conf"

  sleep 120 &
  sleeper_pid=$!
  printf '%s\n' "$sleeper_pid" > "$site_dir/nginx/nginx.pid"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-systemctl-simple "$stub_dir"
  stub-uname-linux "$stub_dir"
  cat > "$stub_dir/nginx" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat > "$stub_dir/ps" <<'EOF'
#!/bin/sh
printf '%s\n' "sleep 120"
EOF
  chmod +x "$stub_dir/nginx"
  chmod +x "$stub_dir/ps"

  # With stale PID handling, serve-site should not claim "already running".
  # It should continue and fail at daemon prerequisite.
  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" \
    SERVICE_DIR="$stub_dir/systemd" \
    run_spell spells/web/serve-site mysite

  if [ "$STATUS" -eq 0 ]; then
    kill -9 "$sleeper_pid" 2>/dev/null || true
    TEST_FAILURE_REASON="serve-site incorrectly treated stale non-nginx PID as running"
    rm -rf "$web_root" "$stub_dir"
    return 1
  fi

  assert_error_contains "daemon not configured"

  if ! kill -0 "$sleeper_pid" 2>/dev/null; then
    TEST_FAILURE_REASON="serve-site should not kill unrelated stale PID process"
    rm -rf "$web_root" "$stub_dir"
    return 1
  fi

  kill -9 "$sleeper_pid" 2>/dev/null || true
  rm -rf "$web_root" "$stub_dir"
}

run_test_case "serve-site --help" test_serve_site_help
run_test_case "serve-site ignores stale non-nginx PID files" \
  test_serve_site_ignores_stale_non_nginx_pid

finish_tests
