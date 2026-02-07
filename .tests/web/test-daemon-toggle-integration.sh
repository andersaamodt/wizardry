#!/bin/sh
# Integration tests for enable/disable/check daemon cycle

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_daemon_toggle_cycle_launchctl() {
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

  # Initial state: daemon not enabled (disabled)
  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" LAUNCHCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/is-site-daemon-enabled mysite
  if [ $? -eq 0 ]; then
    TEST_FAILURE_REASON="Initially should be disabled"
    rm -rf "$web_root" "$stub_dir" "$state_dir"
    return 1
  fi

  # Enable the daemon
  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" LAUNCHCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/enable-site-daemon mysite
  assert_success

  # Check that it's now enabled
  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" LAUNCHCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/is-site-daemon-enabled mysite
  if [ $? -ne 0 ]; then
    TEST_FAILURE_REASON="After enable, should be enabled. Disabled file contents: $(cat "$state_dir/disabled" 2>/dev/null || echo 'MISSING')"
    rm -rf "$web_root" "$stub_dir" "$state_dir"
    return 1
  fi

  # Disable the daemon
  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" LAUNCHCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/disable-site-daemon mysite
  assert_success

  # Check that it's now disabled
  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" LAUNCHCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/is-site-daemon-enabled mysite
  if [ $? -eq 0 ]; then
    TEST_FAILURE_REASON="After disable, should be disabled. Disabled file contents: $(cat "$state_dir/disabled" 2>/dev/null || echo 'MISSING')"
    rm -rf "$web_root" "$stub_dir" "$state_dir"
    return 1
  fi

  # Enable again
  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" LAUNCHCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/enable-site-daemon mysite
  assert_success

  # Check that it's enabled again
  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" LAUNCHCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/is-site-daemon-enabled mysite
  if [ $? -ne 0 ]; then
    TEST_FAILURE_REASON="After re-enable, should be enabled"
    rm -rf "$web_root" "$stub_dir" "$state_dir"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$state_dir"
}

run_test_case "daemon toggle cycle works (enable→check→disable→check→enable)" test_daemon_toggle_cycle_launchctl

finish_tests
