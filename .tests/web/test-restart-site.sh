#!/bin/sh
# Tests for restart-site spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_restart_site_help() {
  run_spell spells/web/restart-site --help
  assert_success
  assert_output_contains "Usage: restart-site"
}

test_restart_site_calls_stop_then_serve() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir"

  stub_dir=$(temp-dir web-wizardry-stub)
  state_dir=$(temp-dir web-wizardry-state)
  cat > "$stub_dir/stop-site" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$state_dir/stop.log"
exit 0
EOF
  cat > "$stub_dir/serve-site" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$state_dir/serve.log"
exit 0
EOF
  cat > "$stub_dir/sleep" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/stop-site" "$stub_dir/serve-site" "$stub_dir/sleep"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" \
    run_spell spells/web/restart-site mysite
  assert_success

  if [ "$(wc -l < "$state_dir/stop.log" 2>/dev/null || echo 0)" -lt 1 ]; then
    TEST_FAILURE_REASON="restart-site did not call stop-site"
    rm -rf "$web_root" "$stub_dir" "$state_dir"
    return 1
  fi
  if [ "$(wc -l < "$state_dir/serve.log" 2>/dev/null || echo 0)" -lt 1 ]; then
    TEST_FAILURE_REASON="restart-site did not call serve-site"
    rm -rf "$web_root" "$stub_dir" "$state_dir"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$state_dir"
}

test_restart_site_retries_after_failed_start() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir"

  stub_dir=$(temp-dir web-wizardry-stub)
  state_dir=$(temp-dir web-wizardry-state)
  cat > "$stub_dir/stop-site" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$state_dir/stop.log"
exit 0
EOF
  cat > "$stub_dir/serve-site" <<EOF
#!/bin/sh
count_file="$state_dir/serve-count"
count=0
[ -f "\$count_file" ] && count=\$(cat "\$count_file")
count=\$((count + 1))
printf '%s' "\$count" > "\$count_file"
if [ "\$count" -eq 1 ]; then
  exit 1
fi
exit 0
EOF
  cat > "$stub_dir/sleep" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/stop-site" "$stub_dir/serve-site" "$stub_dir/sleep"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" \
    run_spell spells/web/restart-site mysite
  assert_success

  serve_count=$(cat "$state_dir/serve-count" 2>/dev/null || echo 0)
  if [ "$serve_count" -ne 2 ]; then
    TEST_FAILURE_REASON="expected 2 serve-site attempts, got $serve_count"
    rm -rf "$web_root" "$stub_dir" "$state_dir"
    return 1
  fi

  # 1 initial stop + 1 cleanup stop before retry
  stop_count=$(wc -l < "$state_dir/stop.log" 2>/dev/null || echo 0)
  if [ "$stop_count" -lt 2 ]; then
    TEST_FAILURE_REASON="expected restart-site to stop before retry (stop count=$stop_count)"
    rm -rf "$web_root" "$stub_dir" "$state_dir"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$state_dir"
}

run_test_case "restart-site --help works" test_restart_site_help
run_test_case "restart-site calls stop-site then serve-site" \
  test_restart_site_calls_stop_then_serve
run_test_case "restart-site retries serve-site after transient failure" \
  test_restart_site_retries_after_failed_start

finish_tests
