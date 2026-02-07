#!/bin/sh
# Tests for disable-site-daemon spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_disable_site_daemon_help() {
  run_spell spells/web/disable-site-daemon --help
  assert_success
  assert_output_contains "Usage: disable-site-daemon"
}

test_disable_site_daemon_calls_systemctl() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/site"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-systemctl-simple "$stub_dir"
  stub-sudo "$stub_dir"

  state_dir=$(temp-dir web-wizardry-state)

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" SYSTEMCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/disable-site-daemon mysite
  assert_success

  log_file="$state_dir/systemctl.log"
  if [ ! -f "$log_file" ]; then
    TEST_FAILURE_REASON="systemctl log missing"
    return 1
  fi
  if ! grep -q "disable wizardry-site-mysite.service" "$log_file"; then
    TEST_FAILURE_REASON="disable command not issued"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$state_dir"
}

test_disable_site_daemon_launchctl_integration() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-launchctl "$stub_dir"
  stub-uname-darwin "$stub_dir"
  stub-sudo "$stub_dir"
  stub-forget-command systemctl "$stub_dir"  # Hide systemctl to test macOS path
  . "$stub_dir/forget-systemctl"  # Apply the has function override

  state_dir=$(temp-dir web-wizardry-state)
  plist_dir="$stub_dir/Library/LaunchDaemons"
  mkdir -p "$plist_dir"
  
  # Create daemon plist
  plist="$plist_dir/org.wizardry.web.mysite.plist"
  touch "$plist"

  # Disable the daemon
  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" LAUNCHCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/disable-site-daemon mysite
  assert_success

  # Check that launchctl disable was called
  log_file="$state_dir/launchctl.log"
  if [ ! -f "$log_file" ]; then
    TEST_FAILURE_REASON="launchctl log missing"
    return 1
  fi
  
  # Should call either 'disable system/...' or 'unload -w ...'
  if ! grep -E "(disable system/org.wizardry.web.mysite|unload -w.*mysite)" "$log_file"; then
    TEST_FAILURE_REASON="disable or unload -w command not found in log: $(cat "$log_file")"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$state_dir"
}

run_test_case "disable-site-daemon --help works" test_disable_site_daemon_help
run_test_case "disable-site-daemon calls systemctl disable" test_disable_site_daemon_calls_systemctl
run_test_case "disable-site-daemon calls launchctl disable (macOS)" test_disable_site_daemon_launchctl_integration

finish_tests
