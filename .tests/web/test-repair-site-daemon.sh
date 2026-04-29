#!/bin/sh
# Tests for repair-site-daemon spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

plist_bool_value() {
  plist_path=$1
  key_name=$2
  awk -v key="$key_name" '
    $0 ~ "<key>" key "</key>" { found=1; next }
    found {
      if ($0 ~ /<true\/>/) { print "true"; exit }
      if ($0 ~ /<false\/>/) { print "false"; exit }
      if ($0 ~ /<key>/ || $0 ~ /<\/dict>/) { exit }
    }
  ' "$plist_path"
}

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
  stub-uname-linux "$stub_dir"
  stub-sudo "$stub_dir"

  state_dir=$(temp-dir web-wizardry-state)
  service_dir="$stub_dir/services"
  mkdir -p "$service_dir"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" WIZARDRY_DIR="$ROOT_DIR" \
    SERVICE_DIR="$service_dir" SYSTEMCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/repair-site-daemon mysite
  if [ "$STATUS" -ne 0 ]; then
    TEST_FAILURE_REASON="repair-site-daemon failed unexpectedly: $ERROR"
    return 1
  fi

  unit_file="$service_dir/wizardry-site-mysite.service"
  if [ ! -f "$unit_file" ]; then
    TEST_FAILURE_REASON="systemd unit not created"
    return 1
  fi
  if ! grep -q "ExecStart=.*run-site-daemon mysite" "$unit_file"; then
    TEST_FAILURE_REASON="unit missing ExecStart"
    return 1
  fi
  if ! grep -q "Environment=WEB_WIZARDRY_ROOT=$web_root" "$unit_file"; then
    TEST_FAILURE_REASON="unit missing WEB_WIZARDRY_ROOT environment"
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

test_repair_site_daemon_launchctl_defaults_to_disabled() {
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
  stub-launchctl "$stub_dir"
  stub-uname-darwin "$stub_dir"
  stub-sudo "$stub_dir"
  stub-forget-command systemctl "$stub_dir"
  . "$stub_dir/forget-systemctl"

  state_dir=$(temp-dir web-wizardry-state)
  plist_dir="$stub_dir/Library/LaunchDaemons"
  mkdir -p "$plist_dir"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" WIZARDRY_DIR="$ROOT_DIR" \
    LAUNCHCTL_STATE_DIR="$state_dir" LAUNCHD_PLIST_DIR="$plist_dir" \
    run_spell spells/web/repair-site-daemon mysite
  if [ "$STATUS" -ne 0 ]; then
    TEST_FAILURE_REASON="repair-site-daemon failed unexpectedly on launchctl path: $ERROR"
    return 1
  fi

  plist_file="$plist_dir/org.wizardry.web.mysite.plist"
  if [ "$(plist_bool_value "$plist_file" RunAtLoad)" != "false" ]; then
    TEST_FAILURE_REASON="RunAtLoad should default to false in launchd plist"
    return 1
  fi
  if [ "$(plist_bool_value "$plist_file" KeepAlive)" != "false" ]; then
    TEST_FAILURE_REASON="KeepAlive should default to false in launchd plist"
    return 1
  fi
  if ! grep -q "<key>WEB_WIZARDRY_ROOT</key>" "$plist_file"; then
    TEST_FAILURE_REASON="launchd plist missing WEB_WIZARDRY_ROOT environment key"
    return 1
  fi

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" WIZARDRY_DIR="$ROOT_DIR" \
    LAUNCHCTL_STATE_DIR="$state_dir" LAUNCHD_PLIST_DIR="$plist_dir" \
    run_spell spells/web/is-site-daemon-enabled mysite
  if [ "$STATUS" -eq 0 ]; then
    TEST_FAILURE_REASON="daemon should be disabled after repair, but is-site-daemon-enabled returned success"
    return 1
  fi

  # Compatibility call should clear stale launchctl disables.
  log_file="$state_dir/launchctl.log"
  if [ ! -f "$log_file" ] || ! grep -q "enable system/org.wizardry.web.mysite" "$log_file"; then
    TEST_FAILURE_REASON="expected launchctl enable compatibility call during repair"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$state_dir"
}

test_repair_site_daemon_rejects_path_shaped_site_name() {
  skip-if-compiled || return $?

  tmpdir=$(make_tempdir)
  web_root="$tmpdir/sites"
  escape_dir="$tmpdir/escape"
  mkdir -p "$web_root" "$escape_dir/site"
  cat > "$escape_dir/site.conf" <<EOF
site-user=$(id -un)
EOF

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-launchctl "$stub_dir"
  stub-uname-darwin "$stub_dir"
  stub-sudo "$stub_dir"
  stub-forget-command systemctl "$stub_dir"
  . "$stub_dir/forget-systemctl"

  state_dir=$(temp-dir web-wizardry-state)
  plist_dir="$stub_dir/Library/LaunchDaemons"
  mkdir -p "$plist_dir"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" WIZARDRY_DIR="$ROOT_DIR" \
    LAUNCHCTL_STATE_DIR="$state_dir" LAUNCHD_PLIST_DIR="$plist_dir" \
    run_spell spells/web/repair-site-daemon ../escape

  assert_failure || return 1
  assert_error_contains "invalid site name" || return 1
  if [ -d "$escape_dir/nginx" ]; then
    TEST_FAILURE_REASON="repair-site-daemon created daemon paths outside WEB_WIZARDRY_ROOT"
    return 1
  fi

  rm -rf "$tmpdir" "$stub_dir" "$state_dir"
}

test_repair_site_daemon_rejects_invalid_imported_site_user() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/site"
  cat > "$site_dir/site.conf" <<'EOF'
site-name=mysite
site-user=#0
EOF

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-systemctl-simple "$stub_dir"
  stub-uname-linux "$stub_dir"
  stub-sudo "$stub_dir"

  state_dir=$(temp-dir web-wizardry-state)
  service_dir="$stub_dir/services"
  mkdir -p "$service_dir"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" WIZARDRY_DIR="$ROOT_DIR" \
    SERVICE_DIR="$service_dir" SYSTEMCTL_STATE_DIR="$state_dir" \
    run_spell spells/web/repair-site-daemon mysite

  assert_failure || return 1
  assert_error_contains "invalid site-user" || return 1
  if [ -f "$service_dir/wizardry-site-mysite.service" ]; then
    TEST_FAILURE_REASON="repair-site-daemon rendered a unit with invalid site-user"
    rm -rf "$web_root" "$stub_dir" "$state_dir"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$state_dir"
}

run_test_case "repair-site-daemon --help works" test_repair_site_daemon_help
run_test_case "repair-site-daemon installs systemd unit" test_repair_site_daemon_installs_systemd_unit
run_test_case "repair-site-daemon defaults launchctl daemon to disabled" \
  test_repair_site_daemon_launchctl_defaults_to_disabled
run_test_case "repair-site-daemon rejects path-shaped site names" \
  test_repair_site_daemon_rejects_path_shaped_site_name
run_test_case "repair-site-daemon rejects invalid imported site-user" \
  test_repair_site_daemon_rejects_invalid_imported_site_user

finish_tests
