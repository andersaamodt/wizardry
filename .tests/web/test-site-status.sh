#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell spells/web/site-status --help
  assert_success
  assert_output_contains "Usage:"
}

test_site_status_ignores_stale_non_nginx_pid() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/build/pages" "$site_dir/nginx"
  touch "$site_dir/build/pages/index.html"

  sleep 120 &
  sleeper_pid=$!
  printf '%s\n' "$sleeper_pid" > "$site_dir/nginx/nginx.pid"

  stub_dir=$(temp-dir web-wizardry-stub)
  cat > "$stub_dir/ps" <<'EOF'
#!/bin/sh
printf '%s\n' "sleep 120"
EOF
  chmod +x "$stub_dir/ps"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" \
    run_spell spells/web/site-status mysite
  assert_success

  if [ "$OUTPUT" != "built, not serving" ]; then
    kill -9 "$sleeper_pid" 2>/dev/null || true
    TEST_FAILURE_REASON="expected 'built, not serving', got '$OUTPUT'"
    rm -rf "$web_root"
    return 1
  fi

  kill -9 "$sleeper_pid" 2>/dev/null || true
  rm -rf "$web_root" "$stub_dir"
}

run_test_case "site-status shows help" test_help
run_test_case "site-status ignores stale non-nginx PID files" \
  test_site_status_ignores_stale_non_nginx_pid
finish_tests
