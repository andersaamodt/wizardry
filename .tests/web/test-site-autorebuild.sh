#!/bin/sh

# Tests for site-autorebuild spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_site_autorebuild_help() {
  run_cmd sh "$ROOT_DIR/spells/web/site-autorebuild" --help
  assert_success
  assert_output_contains "Usage:"
  assert_output_contains "watch-daemon"
}

test_site_autorebuild_requires_target() {
  run_cmd sh "$ROOT_DIR/spells/web/site-autorebuild" enable
  assert_status 2
  assert_error_contains "SITENAME required"
}

test_site_autorebuild_local_enable_run_disable() {
  skip-if-compiled || return $?

  web_root=$(temp-dir site-autorebuild-web)
  site_root="$web_root/testsite"
  mkdir -p "$site_root/site/pages"
  printf '%s\n' '# Test page' > "$site_root/site/pages/index.md"

  fake_wizardry=$(temp-dir site-autorebuild-wizardry)
  mkdir -p "$fake_wizardry/spells/web"
  build_log=$(temp-file site-autorebuild-build-log)
  cat > "$fake_wizardry/spells/web/build" <<'EOS'
#!/bin/sh
set -eu
printf '%s\n' "$1" >> "${SITE_AUTOREBUILD_BUILD_LOG:?}"
EOS
  chmod +x "$fake_wizardry/spells/web/build"

  stub_dir=$(temp-dir site-autorebuild-stub)
  cron_file=$(temp-file site-autorebuild-cron)
  cat > "$stub_dir/crontab" <<'EOS'
#!/bin/sh
set -eu
state_file=${CRON_STUB_FILE:?}
if [ "${1-}" = "-l" ]; then
  [ -f "$state_file" ] || exit 1
  cat "$state_file"
  exit 0
fi
[ $# -eq 1 ] || exit 2
cat "$1" > "$state_file"
EOS
  chmod +x "$stub_dir/crontab"

  run_cmd env \
    PATH="$stub_dir:/usr/bin:/bin:/usr/sbin:/sbin" \
    WEB_WIZARDRY_ROOT="$web_root" \
    WIZARDRY_DIR="$fake_wizardry" \
    CRON_STUB_FILE="$cron_file" \
    SITE_AUTOREBUILD_BUILD_LOG="$build_log" \
    sh "$ROOT_DIR/spells/web/site-autorebuild" enable testsite
  assert_success
  assert_output_contains "enabled=yes"
  assert_output_contains "cron_installed=yes"

  printf '%s\n' '# Changed' >> "$site_root/site/pages/index.md"
  run_cmd env \
    PATH="$stub_dir:/usr/bin:/bin:/usr/sbin:/sbin" \
    WEB_WIZARDRY_ROOT="$web_root" \
    WIZARDRY_DIR="$fake_wizardry" \
    CRON_STUB_FILE="$cron_file" \
    SITE_AUTOREBUILD_BUILD_LOG="$build_log" \
    sh "$ROOT_DIR/spells/web/site-autorebuild" run testsite
  assert_success
  assert_output_contains "enabled=yes"

  if ! grep -q '^testsite$' "$build_log"; then
    TEST_FAILURE_REASON="build spell was not invoked for testsite"
    rm -rf "$web_root" "$fake_wizardry" "$stub_dir"
    return 1
  fi

  run_cmd env \
    PATH="$stub_dir:/usr/bin:/bin:/usr/sbin:/sbin" \
    WEB_WIZARDRY_ROOT="$web_root" \
    WIZARDRY_DIR="$fake_wizardry" \
    CRON_STUB_FILE="$cron_file" \
    SITE_AUTOREBUILD_BUILD_LOG="$build_log" \
    sh "$ROOT_DIR/spells/web/site-autorebuild" disable testsite
  assert_success
  assert_output_contains "enabled=no"

  rm -rf "$web_root" "$fake_wizardry" "$stub_dir"
}

run_test_case "site-autorebuild --help" test_site_autorebuild_help
run_test_case "site-autorebuild validates target" test_site_autorebuild_requires_target
run_test_case "site-autorebuild local enable/run/disable" test_site_autorebuild_local_enable_run_disable

finish_tests
