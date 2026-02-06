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

run_test_case "disable-site-daemon --help works" test_disable_site_daemon_help
run_test_case "disable-site-daemon calls systemctl disable" test_disable_site_daemon_calls_systemctl

finish_tests
