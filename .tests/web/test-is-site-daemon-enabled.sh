#!/bin/sh
# Tests for is-site-daemon-enabled spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_is_site_daemon_enabled_help() {
  run_spell spells/web/is-site-daemon-enabled --help
  assert_success
  assert_output_contains "Usage: is-site-daemon-enabled"
}

write_systemctl_stub() {
  dir=$1
  cat >"$dir/systemctl" <<'EOF'
#!/bin/sh
case "$1" in
  is-enabled)
    exit "${SYSTEMCTL_IS_ENABLED_STATUS:-1}"
    ;;
  *)
    exit 0
    ;;
esac
EOF
  chmod +x "$dir/systemctl"
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

write_uname_darwin() {
  dir=$1
  cat >"$dir/uname" <<'EOF'
#!/bin/sh
printf 'Darwin\n'
EOF
  chmod +x "$dir/uname"
}

test_is_site_daemon_enabled_true_systemctl() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  mkdir -p "$web_root/mysite"

  stub_dir=$(temp-dir web-wizardry-stub)
  write_systemctl_stub "$stub_dir"
  stub-uname-linux "$stub_dir"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" SYSTEMCTL_IS_ENABLED_STATUS=0 \
    run_spell spells/web/is-site-daemon-enabled mysite
  assert_success

  rm -rf "$web_root" "$stub_dir"
}

test_is_site_daemon_enabled_false_systemctl() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  mkdir -p "$web_root/mysite"

  stub_dir=$(temp-dir web-wizardry-stub)
  write_systemctl_stub "$stub_dir"
  stub-uname-linux "$stub_dir"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" SYSTEMCTL_IS_ENABLED_STATUS=1 \
    run_spell spells/web/is-site-daemon-enabled mysite
  assert_failure

  rm -rf "$web_root" "$stub_dir"
}

test_is_site_daemon_enabled_true_launchctl() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  mkdir -p "$web_root/mysite"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-launchctl "$stub_dir"
  write_uname_darwin "$stub_dir"
  stub-forget-command systemctl "$stub_dir"
  . "$stub_dir/forget-systemctl"

  plist_dir="$stub_dir/Library/LaunchDaemons"
  mkdir -p "$plist_dir"
  write_plist "$plist_dir/org.wizardry.web.mysite.plist" true true

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" LAUNCHD_PLIST_DIR="$plist_dir" \
    run_spell spells/web/is-site-daemon-enabled mysite
  assert_success

  rm -rf "$web_root" "$stub_dir"
}

test_is_site_daemon_enabled_false_launchctl() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  mkdir -p "$web_root/mysite"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-launchctl "$stub_dir"
  write_uname_darwin "$stub_dir"
  stub-forget-command systemctl "$stub_dir"
  . "$stub_dir/forget-systemctl"

  plist_dir="$stub_dir/Library/LaunchDaemons"
  mkdir -p "$plist_dir"
  write_plist "$plist_dir/org.wizardry.web.mysite.plist" false false

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" LAUNCHD_PLIST_DIR="$plist_dir" \
    run_spell spells/web/is-site-daemon-enabled mysite
  assert_failure

  rm -rf "$web_root" "$stub_dir"
}

test_is_site_daemon_enabled_false_launchctl_partial_flags() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  mkdir -p "$web_root/mysite"

  stub_dir=$(temp-dir web-wizardry-stub)
  stub-launchctl "$stub_dir"
  write_uname_darwin "$stub_dir"
  stub-forget-command systemctl "$stub_dir"
  . "$stub_dir/forget-systemctl"

  plist_dir="$stub_dir/Library/LaunchDaemons"
  mkdir -p "$plist_dir"
  write_plist "$plist_dir/org.wizardry.web.mysite.plist" true false

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" LAUNCHD_PLIST_DIR="$plist_dir" \
    run_spell spells/web/is-site-daemon-enabled mysite
  assert_failure

  rm -rf "$web_root" "$stub_dir"
}

run_test_case "is-site-daemon-enabled --help works" test_is_site_daemon_enabled_help
run_test_case "is-site-daemon-enabled returns success when enabled (systemctl)" \
  test_is_site_daemon_enabled_true_systemctl
run_test_case "is-site-daemon-enabled returns failure when disabled (systemctl)" \
  test_is_site_daemon_enabled_false_systemctl
run_test_case "is-site-daemon-enabled returns success when enabled (launchctl plist flags)" \
  test_is_site_daemon_enabled_true_launchctl
run_test_case "is-site-daemon-enabled returns failure when disabled (launchctl plist flags)" \
  test_is_site_daemon_enabled_false_launchctl
run_test_case "is-site-daemon-enabled requires both RunAtLoad and KeepAlive true" \
  test_is_site_daemon_enabled_false_launchctl_partial_flags

finish_tests
