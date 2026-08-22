#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_spell "spells/.arcana/mobile-debugging/mobile-debugging-status" --help
  assert_success || return 1
  assert_output_contains "Usage: mobile-debugging-status" || return 1
}

reports_not_installed() {
  tmpdir=$(make_tempdir)

  run_cmd env XDG_DATA_HOME="$tmpdir/data" \
    "$ROOT_DIR/spells/.arcana/mobile-debugging/mobile-debugging-status"

  assert_success || return 1
  assert_output_contains "not installed" || return 1
}

reports_installed_with_tor_adb() {
  tmpdir=$(make_tempdir)
  data_home="$tmpdir/data"
  stub_dir="$tmpdir/bin"
  java_home="$data_home/theurgy/mobile-debugging/java/current/Contents/Home/bin"
  adb_dir="$data_home/theurgy/mobile-debugging/android-sdk/platform-tools"
  maestro_dir="$data_home/theurgy/mobile-debugging/maestro-cli/current/bin"
  mkdir -p "$stub_dir" "$java_home" "$adb_dir" "$maestro_dir"

  cat >"$java_home/java" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$java_home/java"

  cat >"$adb_dir/adb" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$adb_dir/adb"

  cat >"$maestro_dir/maestro" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$maestro_dir/maestro"

  cat >"$stub_dir/tor" <<'SH'
#!/bin/sh
exit 0
SH
  cat >"$stub_dir/socat" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$stub_dir/tor" "$stub_dir/socat"

  run_cmd env PATH="$stub_dir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" XDG_DATA_HOME="$data_home" \
    "$ROOT_DIR/spells/.arcana/mobile-debugging/mobile-debugging-status"

  assert_success || return 1
  assert_output_contains "installed + Tor adb" || return 1
}

run_test_case "mobile-debugging-status shows help" shows_help
run_test_case "mobile-debugging-status reports not installed" reports_not_installed
run_test_case "mobile-debugging-status reports installed tools with Tor adb" \
  reports_installed_with_tor_adb

finish_tests
