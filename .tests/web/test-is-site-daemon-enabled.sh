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

test_is_site_daemon_enabled_true() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir"

  stub_dir=$(temp-dir web-wizardry-stub)
  write_systemctl_stub "$stub_dir"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" SYSTEMCTL_IS_ENABLED_STATUS=0 \
    run_spell spells/web/is-site-daemon-enabled mysite
  assert_success

  rm -rf "$web_root" "$stub_dir"
}

test_is_site_daemon_enabled_false() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir"

  stub_dir=$(temp-dir web-wizardry-stub)
  write_systemctl_stub "$stub_dir"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" SYSTEMCTL_IS_ENABLED_STATUS=1 \
    run_spell spells/web/is-site-daemon-enabled mysite
  assert_failure

  rm -rf "$web_root" "$stub_dir"
}

write_launchctl_stub() {
  dir=$1
  cat >"$dir/launchctl" <<'EOF'
#!/bin/sh
case "$1" in
  print-disabled)
    printf '{\n'
    if [ -n "${LAUNCHCTL_DISABLED_LABELS-}" ]; then
      printf '  %s\n' "$LAUNCHCTL_DISABLED_LABELS"
    fi
    printf '}\n'
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
  chmod +x "$dir/launchctl"
}

write_uname_darwin() {
  dir=$1
  cat >"$dir/uname" <<'EOF'
#!/bin/sh
printf 'Darwin\n'
EOF
  chmod +x "$dir/uname"
}

test_is_site_daemon_enabled_launchctl_enabled() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir"

  stub_dir=$(temp-dir web-wizardry-stub)
  write_launchctl_stub "$stub_dir"
  write_uname_darwin "$stub_dir"
  
  # Create plist file
  plist_dir="$stub_dir/Library/LaunchDaemons"
  mkdir -p "$plist_dir"
  touch "$plist_dir/org.wizardry.web.mysite.plist"

  # Daemon NOT in disabled list = enabled
  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" LAUNCHCTL_DISABLED_LABELS="" \
    run_spell spells/web/is-site-daemon-enabled mysite
  assert_success

  rm -rf "$web_root" "$stub_dir"
}

test_is_site_daemon_enabled_launchctl_disabled() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-test)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir"

  stub_dir=$(temp-dir web-wizardry-stub)
  write_launchctl_stub "$stub_dir"
  write_uname_darwin "$stub_dir"
  
  # Create plist file
  plist_dir="$stub_dir/Library/LaunchDaemons"
  mkdir -p "$plist_dir"
  touch "$plist_dir/org.wizardry.web.mysite.plist"

  # Daemon IN disabled list with => true = disabled
  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" \
    LAUNCHCTL_DISABLED_LABELS='"org.wizardry.web.mysite" => true' \
    run_spell spells/web/is-site-daemon-enabled mysite
  assert_failure

  rm -rf "$web_root" "$stub_dir"
}

run_test_case "is-site-daemon-enabled --help works" test_is_site_daemon_enabled_help
run_test_case "is-site-daemon-enabled returns success when enabled (systemctl)" test_is_site_daemon_enabled_true
run_test_case "is-site-daemon-enabled returns failure when disabled (systemctl)" test_is_site_daemon_enabled_false
run_test_case "is-site-daemon-enabled returns success when enabled (launchctl)" test_is_site_daemon_enabled_launchctl_enabled
run_test_case "is-site-daemon-enabled returns failure when disabled (launchctl)" test_is_site_daemon_enabled_launchctl_disabled

finish_tests
