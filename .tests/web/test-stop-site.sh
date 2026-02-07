#!/bin/sh
# Test stop-site spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_stop_site_help() {
  run_spell spells/web/stop-site --help
  assert_success
  assert_output_contains "Usage:"
}

test_stop_site_uses_system_launchctl_bootout() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-launchctl "$stub_dir"
  stub-uname-darwin "$stub_dir"
  stub-sudo "$stub_dir"
  stub-forget-command systemctl "$stub_dir"
  . "$stub_dir/forget-systemctl"

  state_dir=$(temp-dir web-wizardry-state)
  plist_dir="$stub_dir/Library/LaunchDaemons"
  mkdir -p "$plist_dir"
  touch "$plist_dir/org.wizardry.web.mysite.plist"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" LAUNCHCTL_STATE_DIR="$state_dir" \
    LAUNCHD_PLIST_DIR="$plist_dir" \
    run_spell spells/web/stop-site mysite
  assert_success

  log_file="$state_dir/launchctl.log"
  if [ ! -f "$log_file" ]; then
    TEST_FAILURE_REASON="launchctl log missing"
    return 1
  fi

  if ! grep -q "bootout system/org.wizardry.web.mysite" "$log_file"; then
    TEST_FAILURE_REASON="expected system-domain bootout call, got: $(cat "$log_file")"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$state_dir"
}

test_stop_site_kills_nginx_pid_when_daemon_missing() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/nginx"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-systemctl-simple "$stub_dir"
  stub-uname-linux "$stub_dir"
  stub-sudo "$stub_dir"
  state_dir=$(temp-dir web-wizardry-state)
  cat > "$stub_dir/ps" <<EOF
#!/bin/sh
printf '%s\n' "nginx -p $site_dir"
EOF
  chmod +x "$stub_dir/ps"

  # Create a long-running process whose command line clearly identifies
  # an nginx process bound to this site path.
  cat > "$stub_dir/nginx-daemon" <<EOF
#!/bin/sh
while :; do
  sleep 5
done
EOF
  chmod +x "$stub_dir/nginx-daemon"
  "$stub_dir/nginx-daemon" -p "$site_dir" &
  sleeper_pid=$!
  printf '%s\n' "$sleeper_pid" > "$site_dir/nginx/nginx.pid"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" SYSTEMCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/stop-site mysite
  assert_success

  if kill -0 "$sleeper_pid" 2>/dev/null; then
    kill -9 "$sleeper_pid" 2>/dev/null || true
    TEST_FAILURE_REASON="expected stop-site to kill nginx pid fallback process"
    return 1
  fi

  if [ -f "$site_dir/nginx/nginx.pid" ]; then
    TEST_FAILURE_REASON="expected nginx.pid to be removed after fallback stop"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$state_dir"
}

test_stop_site_does_not_kill_unrelated_pid_when_daemon_missing() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/nginx"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-systemctl-simple "$stub_dir"
  stub-uname-linux "$stub_dir"
  stub-sudo "$stub_dir"
  state_dir=$(temp-dir web-wizardry-state)

  cat > "$stub_dir/non-nginx-daemon" <<'EOF'
#!/bin/sh
while :; do
  sleep 5
done
EOF
  chmod +x "$stub_dir/non-nginx-daemon"

  "$stub_dir/non-nginx-daemon" &
  sleeper_pid=$!
  printf '%s\n' "$sleeper_pid" > "$site_dir/nginx/nginx.pid"
cat > "$stub_dir/ps" <<'EOF'
#!/bin/sh
printf '%s\n' "non-nginx-daemon"
EOF
  chmod +x "$stub_dir/ps"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" SYSTEMCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/stop-site mysite
  assert_success

  if ! kill -0 "$sleeper_pid" 2>/dev/null; then
    TEST_FAILURE_REASON="stop-site should not kill unrelated process from stale PID file"
    rm -rf "$web_root" "$stub_dir" "$state_dir"
    return 1
  fi

  if [ -f "$site_dir/nginx/nginx.pid" ]; then
    TEST_FAILURE_REASON="expected stale nginx.pid to be removed"
    rm -rf "$web_root" "$stub_dir" "$state_dir"
    return 1
  fi

  kill -9 "$sleeper_pid" 2>/dev/null || true
  rm -rf "$web_root" "$stub_dir" "$state_dir"
}

run_test_case "stop-site --help" test_stop_site_help
run_test_case "stop-site uses system launchctl bootout on macOS" \
  test_stop_site_uses_system_launchctl_bootout
run_test_case "stop-site kills nginx PID when daemon config is missing" \
  test_stop_site_kills_nginx_pid_when_daemon_missing
run_test_case "stop-site ignores unrelated stale PID files when daemon is missing" \
  test_stop_site_does_not_kill_unrelated_pid_when_daemon_missing

finish_tests
