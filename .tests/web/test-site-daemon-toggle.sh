#!/bin/sh
# Tests for site daemon enable/disable spells

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_enable_site_daemon_help() {
  run_spell spells/web/enable-site-daemon --help
  assert_success
  assert_output_contains "Usage: enable-site-daemon"
}

test_disable_site_daemon_help() {
  run_spell spells/web/disable-site-daemon --help
  assert_success
  assert_output_contains "Usage: disable-site-daemon"
}

test_enable_disable_site_daemon_systemd() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/site"
  cat > "$site_dir/site.conf" <<EOF
# Site configuration for mysite
site-name=mysite
site-user=$(id -un)
EOF

  stub_dir=$(temp-dir web-wizardry-stub)
  cat > "$stub_dir/systemctl" <<'EOF'
#!/bin/sh
state_dir=${SYSTEMCTL_STATE_DIR:-$(mktemp -d)}
mkdir -p "$state_dir"
log_file="$state_dir/systemctl.log"
printf '%s\n' "$*" >>"$log_file"
exit 0
EOF
  chmod +x "$stub_dir/systemctl"

  state_dir=$(temp-dir web-wizardry-state)
  service_dir="$stub_dir/services"
  mkdir -p "$service_dir"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" WIZARDRY_DIR="$ROOT_DIR" \
    SERVICE_DIR="$service_dir" SYSTEMCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/enable-site-daemon mysite
  assert_success

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" WIZARDRY_DIR="$ROOT_DIR" \
    SERVICE_DIR="$service_dir" SYSTEMCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/disable-site-daemon mysite
  assert_success

  log_file="$state_dir/systemctl.log"
  if ! grep -q "enable wizardry-site-mysite.service" "$log_file"; then
    TEST_FAILURE_REASON="systemctl enable not called"
    return 1
  fi
  if ! grep -q "disable wizardry-site-mysite.service" "$log_file"; then
    TEST_FAILURE_REASON="systemctl disable not called"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$state_dir"
}

run_test_case "enable-site-daemon --help works" test_enable_site_daemon_help
run_test_case "disable-site-daemon --help works" test_disable_site_daemon_help
run_test_case "enable/disable site daemon uses systemctl" test_enable_disable_site_daemon_systemd

finish_tests
