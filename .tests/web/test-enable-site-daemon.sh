#!/bin/sh
# Tests for enable-site-daemon spell

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

test_enable_site_daemon_calls_systemctl() {
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
  stub-systemctl-simple "$stub_dir"
  stub-sudo "$stub_dir"

  state_dir=$(temp-dir web-wizardry-state)
  service_dir="$stub_dir/services"
  mkdir -p "$service_dir"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" WIZARDRY_DIR="$ROOT_DIR" \
    SERVICE_DIR="$service_dir" SYSTEMCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/enable-site-daemon mysite
  assert_success

  log_file="$state_dir/systemctl.log"
  if [ ! -f "$log_file" ]; then
    TEST_FAILURE_REASON="systemctl log missing"
    return 1
  fi
  if ! grep -q "enable wizardry-site-mysite.service" "$log_file"; then
    TEST_FAILURE_REASON="enable command not issued"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$state_dir"
}

test_enable_site_daemon_launchctl_integration() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-launchctl "$stub_dir"
  stub-uname-darwin "$stub_dir"
  stub-sudo "$stub_dir"

  state_dir=$(temp-dir web-wizardry-state)
  plist_dir="$stub_dir/Library/LaunchDaemons"
  mkdir -p "$plist_dir"
  
  # Create daemon plist
  plist="$plist_dir/org.wizardry.web.mysite.plist"
  touch "$plist"

  # Enable the daemon
  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" LAUNCHCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/enable-site-daemon mysite
  assert_success

  # Check that launchctl enable was called
  log_file="$state_dir/launchctl.log"
  if [ ! -f "$log_file" ]; then
    TEST_FAILURE_REASON="launchctl log missing"
    return 1
  fi
  
  # Should call either 'enable system/...' or 'load -w ...'
  if ! grep -E "(enable system/org.wizardry.web.mysite|load -w.*mysite)" "$log_file"; then
    TEST_FAILURE_REASON="enable or load -w command not found in log: $(cat "$log_file")"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$state_dir"
}

run_test_case "enable-site-daemon --help works" test_enable_site_daemon_help
run_test_case "enable-site-daemon calls systemctl enable" test_enable_site_daemon_calls_systemctl
run_test_case "enable-site-daemon calls launchctl enable (macOS)" test_enable_site_daemon_launchctl_integration

finish_tests
