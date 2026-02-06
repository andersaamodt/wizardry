#!/bin/sh
# Tests for repair-site-daemon spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_repair_site_daemon_help() {
  run_spell spells/web/repair-site-daemon --help
  assert_success
  assert_output_contains "Usage: repair-site-daemon"
}

test_repair_site_daemon_installs_systemd_unit() {
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

  state_dir=$(temp-dir web-wizardry-state)
  service_dir="$stub_dir/services"
  mkdir -p "$service_dir"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" WIZARDRY_DIR="$ROOT_DIR" \
    SERVICE_DIR="$service_dir" SYSTEMCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/repair-site-daemon mysite
  assert_success

  unit_file="$service_dir/wizardry-site-mysite.service"
  if [ ! -f "$unit_file" ]; then
    TEST_FAILURE_REASON="systemd unit not created"
    return 1
  fi
  if ! grep -q "ExecStart=.*run-site-daemon mysite" "$unit_file"; then
    TEST_FAILURE_REASON="unit missing ExecStart"
    return 1
  fi

  log_file="$state_dir/systemctl.log"
  if [ ! -f "$log_file" ]; then
    TEST_FAILURE_REASON="systemctl log missing"
    return 1
  fi
  if ! grep -q "daemon-reload" "$log_file"; then
    TEST_FAILURE_REASON="daemon-reload not called"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$state_dir"
}

run_test_case "repair-site-daemon --help works" test_repair_site_daemon_help
run_test_case "repair-site-daemon installs systemd unit" test_repair_site_daemon_installs_systemd_unit

finish_tests
