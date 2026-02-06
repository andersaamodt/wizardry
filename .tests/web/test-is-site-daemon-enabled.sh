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

run_test_case "is-site-daemon-enabled --help works" test_is_site_daemon_enabled_help
run_test_case "is-site-daemon-enabled returns success when enabled" test_is_site_daemon_enabled_true
run_test_case "is-site-daemon-enabled returns failure when disabled" test_is_site_daemon_enabled_false

finish_tests
