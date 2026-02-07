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

write_plist() {
  plist_path=$1
  run_at_load=$2
  keep_alive=$3
  cat >"$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>org.wizardry.web.mysite</string>
  <key>RunAtLoad</key>
  <$run_at_load/>
  <key>KeepAlive</key>
  <$keep_alive/>
</dict>
</plist>
EOF
}

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
  stub-uname-linux "$stub_dir"
  stub-sudo "$stub_dir"

  state_dir=$(temp-dir web-wizardry-state)
  service_dir="$stub_dir/services"
  mkdir -p "$service_dir"
  touch "$service_dir/wizardry-site-mysite.service"

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

test_enable_site_daemon_launchctl_updates_plist() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  mkdir -p "$web_root/mysite"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-launchctl "$stub_dir"
  stub-uname-darwin "$stub_dir"
  stub-sudo "$stub_dir"
  stub-forget-command systemctl "$stub_dir"
  . "$stub_dir/forget-systemctl"

  state_dir=$(temp-dir web-wizardry-state)
  plist_dir="$stub_dir/Library/LaunchDaemons"
  mkdir -p "$plist_dir"
  plist="$plist_dir/org.wizardry.web.mysite.plist"
  write_plist "$plist" false false

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" LAUNCHCTL_STATE_DIR="$state_dir" \
    LAUNCHD_PLIST_DIR="$plist_dir" \
    run_spell spells/web/enable-site-daemon mysite
  assert_success

  if [ "$(plist_bool_value "$plist" RunAtLoad)" != "true" ]; then
    TEST_FAILURE_REASON="RunAtLoad not updated to true"
    return 1
  fi
  if [ "$(plist_bool_value "$plist" KeepAlive)" != "true" ]; then
    TEST_FAILURE_REASON="KeepAlive not updated to true"
    return 1
  fi

  # Compatibility path should attempt to clear stale launchctl disables.
  log_file="$state_dir/launchctl.log"
  if [ ! -f "$log_file" ] || ! grep -q "enable system/org.wizardry.web.mysite" "$log_file"; then
    TEST_FAILURE_REASON="expected launchctl enable compatibility call"
    return 1
  fi

  rm -rf "$web_root" "$stub_dir" "$state_dir"
}

test_enable_site_daemon_fails_when_plist_missing() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  mkdir -p "$web_root/mysite"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-launchctl "$stub_dir"
  stub-uname-darwin "$stub_dir"
  stub-sudo "$stub_dir"
  stub-forget-command systemctl "$stub_dir"
  . "$stub_dir/forget-systemctl"

  state_dir=$(temp-dir web-wizardry-state)
  plist_dir="$stub_dir/Library/LaunchDaemons"
  mkdir -p "$plist_dir"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" LAUNCHCTL_STATE_DIR="$state_dir" \
    LAUNCHD_PLIST_DIR="$plist_dir" \
    run_spell spells/web/enable-site-daemon mysite
  assert_failure
  assert_error_contains "daemon not configured"

  rm -rf "$web_root" "$stub_dir" "$state_dir"
}

run_test_case "enable-site-daemon --help works" test_enable_site_daemon_help
run_test_case "enable-site-daemon calls systemctl enable" test_enable_site_daemon_calls_systemctl
run_test_case "enable-site-daemon updates launchctl plist flags" \
  test_enable_site_daemon_launchctl_updates_plist
run_test_case "enable-site-daemon fails when launchctl plist is missing" \
  test_enable_site_daemon_fails_when_plist_missing

finish_tests
