#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_cmd "$ROOT_DIR/spells/wards/firewalled-maestro" --help
  assert_success
  assert_output_contains "Usage: firewalled-maestro"
}

routes_adb_through_firewalled_adb() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/bin"
  data_home="$tmpdir/data"
  adb_root="$data_home/theurgy/mobile-debugging/android-sdk/platform-tools"
  maestro_root="$data_home/theurgy/mobile-debugging/maestro-cli/current"
  java_home="$data_home/theurgy/mobile-debugging/java/current/Contents/Home"
  mkdir -p "$stub_dir" "$adb_root" "$maestro_root/bin" "$java_home/bin"

  cat >"$java_home/bin/java" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$java_home/bin/java"

  cat >"$maestro_root/bin/maestro" <<'SH'
#!/bin/sh
printf '%s\n' "${JAVA_HOME:-}" >"${MAESTRO_JAVA_HOME_LOG:?}"
adb devices
SH
  chmod +x "$maestro_root/bin/maestro"

  cat >"$adb_root/adb" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"${ADB_LOG:?}"
exit 0
SH
  chmod +x "$adb_root/adb"

  cat >"$stub_dir/firewall" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"${FIREWALL_LOG:?}"
while [ "$#" -gt 0 ]; do
  [ "$1" = "--" ] && break
  shift
done
shift
exec "$@"
SH
  chmod +x "$stub_dir/firewall"

  run_cmd env PATH="$stub_dir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" XDG_DATA_HOME="$data_home" FIREWALL_LOG="$tmpdir/firewall.log" \
    ADB_LOG="$tmpdir/adb.log" \
    MAESTRO_JAVA_HOME_LOG="$tmpdir/java-home.log" \
    "$ROOT_DIR/spells/wards/firewalled-maestro" --serial 192.168.1.9:5555 --allow 192.168.1.10 -- devices

  assert_success || return 1
  assert_file_contains "$tmpdir/java-home.log" "$java_home"
  assert_file_contains "$tmpdir/firewall.log" "--allow-localhost"
  assert_file_contains "$tmpdir/firewall.log" "--allow"
  assert_file_contains "$tmpdir/firewall.log" "192.168.1.10"
  assert_file_contains "$tmpdir/firewall.log" "192.168.1.9:5555"
  assert_file_contains "$tmpdir/adb.log" "-L"
  assert_file_contains "$tmpdir/adb.log" "tcp:localhost:"
  assert_file_contains "$tmpdir/adb.log" "connect"
  assert_file_contains "$tmpdir/adb.log" "-P"
  assert_file_contains "$tmpdir/adb.log" "devices"
}

run_test_case "firewalled-maestro shows help" shows_help
run_test_case "firewalled-maestro routes adb through firewalled-adb" routes_adb_through_firewalled_adb

uses_direct_java_entrypoint_for_managed_install() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/bin"
  data_home="$tmpdir/data"
  adb_root="$data_home/theurgy/mobile-debugging/android-sdk/platform-tools"
  maestro_root="$data_home/theurgy/mobile-debugging/maestro-cli/current"
  java_home="$data_home/theurgy/mobile-debugging/java/current/Contents/Home"
  mkdir -p "$stub_dir" "$adb_root" "$maestro_root/bin" "$maestro_root/lib" "$java_home/bin"

  : >"$maestro_root/lib/maestro-cli.jar"

  cat >"$maestro_root/bin/maestro" <<'SH'
#!/bin/sh
exit 99
SH
  chmod +x "$maestro_root/bin/maestro"

  cat >"$java_home/bin/java" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"${JAVA_ARGS_LOG:?}"
exit 0
SH
  chmod +x "$java_home/bin/java"

  cat >"$adb_root/adb" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$adb_root/adb"

  cat >"$stub_dir/firewall" <<'SH'
#!/bin/sh
while [ "$#" -gt 0 ]; do
  [ "$1" = "--" ] && break
  shift
done
shift
exec "$@"
SH
  chmod +x "$stub_dir/firewall"

  run_cmd env PATH="$stub_dir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" XDG_DATA_HOME="$data_home" JAVA_ARGS_LOG="$tmpdir/java-args.log" \
    "$ROOT_DIR/spells/wards/firewalled-maestro" -- --version

  assert_success || return 1
  assert_file_contains "$tmpdir/java-args.log" "-classpath"
  assert_file_contains "$tmpdir/java-args.log" "$maestro_root/lib/*"
  assert_file_contains "$tmpdir/java-args.log" "maestro.cli.AppKt"
  assert_file_contains "$tmpdir/java-args.log" "--version"
}

run_test_case "firewalled-maestro uses direct Java entrypoint for managed installs" uses_direct_java_entrypoint_for_managed_install

finish_tests
