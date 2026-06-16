#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_spell spells/wards/firewalled-adb --help
  assert_success
  assert_output_contains "Usage: firewalled-adb"
}

outer_wrapper_uses_firewall_and_serial_allowlist() {
  tmpdir=$(make_tempdir)
  sdk_root="$tmpdir/data"
  mkdir -p "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools"

  cat >"$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools/adb" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"${ADB_LOG:?}"
exit 0
SH
  chmod +x "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools/adb"

  cat >"$tmpdir/firewall" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"${FIREWALL_LOG:?}"
while [ "$#" -gt 0 ]; do
  [ "$1" = "--" ] && break
  shift
done
shift
exec "$@"
SH
  chmod +x "$tmpdir/firewall"

  FIREWALL_LOG="$tmpdir/firewall.log" ADB_LOG="$tmpdir/adb.log" run_cmd env XDG_DATA_HOME="$sdk_root" PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" FIREWALL_LOG="$tmpdir/firewall.log" ADB_LOG="$tmpdir/adb.log" \
    "$ROOT_DIR/spells/wards/firewalled-adb" --serial 127.0.0.1:5555 -- shell getprop ro.product.model

  assert_success || return 1
  assert_file_contains "$tmpdir/firewall.log" "--allow-localhost"
  assert_file_contains "$tmpdir/firewall.log" "127.0.0.1:5555"
  assert_file_contains "$tmpdir/adb.log" "connect"
  assert_file_contains "$tmpdir/adb.log" "-s"
}

version_without_serial_does_not_trip_linebreak_guard() {
  tmpdir=$(make_tempdir)
  sdk_root="$tmpdir/data"
  mkdir -p "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools"

  cat >"$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools/adb" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"${ADB_LOG:?}"
exit 0
SH
  chmod +x "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools/adb"

  cat >"$tmpdir/firewall" <<'SH'
#!/bin/sh
while [ "$#" -gt 0 ]; do
  [ "$1" = "--" ] && break
  shift
done
shift
exec "$@"
SH
  chmod +x "$tmpdir/firewall"

  ADB_LOG="$tmpdir/adb.log" run_cmd env XDG_DATA_HOME="$sdk_root" PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" ADB_LOG="$tmpdir/adb.log" \
    "$ROOT_DIR/spells/wards/firewalled-adb" -- version

  assert_success || return 1
  assert_file_contains "$tmpdir/adb.log" "version"
}

retries_remote_connect_before_running_command() {
  tmpdir=$(make_tempdir)
  sdk_root="$tmpdir/data"
  mkdir -p "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools"

  cat >"$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools/adb" <<'SH'
#!/bin/sh
count_file=${ADB_CONNECT_COUNT:?}
log_file=${ADB_LOG:?}

case "${1-}" in
  kill-server|start-server)
    exit 0
    ;;
  connect)
    count=$(cat "$count_file" 2>/dev/null || printf '0')
    count=$((count + 1))
    printf '%s' "$count" >"$count_file"
    if [ "$count" -lt 2 ]; then
      exit 1
    fi
    printf '%s\n' "connected to ${2-}" >&2
    exit 0
    ;;
  -s)
    shift
    serial=$1
    shift
    case "${1-}" in
      get-state)
        count=$(cat "$count_file" 2>/dev/null || printf '0')
        [ "$count" -ge 2 ] || exit 1
        printf '%s\n' device
        exit 0
        ;;
    esac
    printf '%s\n' "$serial $*" >>"$log_file"
    exit 0
    ;;
esac

printf '%s\n' "$*" >>"$log_file"
exit 0
SH
  chmod +x "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools/adb"

  cat >"$tmpdir/firewall" <<'SH'
#!/bin/sh
while [ "$#" -gt 0 ]; do
  [ "$1" = "--" ] && break
  shift
done
shift
exec "$@"
SH
  chmod +x "$tmpdir/firewall"

  ADB_LOG="$tmpdir/adb.log" ADB_CONNECT_COUNT="$tmpdir/connect.count" run_cmd env \
    XDG_DATA_HOME="$sdk_root" PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    ADB_LOG="$tmpdir/adb.log" ADB_CONNECT_COUNT="$tmpdir/connect.count" \
    "$ROOT_DIR/spells/wards/firewalled-adb" --serial 127.0.0.1:5555 -- shell getprop ro.product.model

  assert_success || return 1
  assert_file_contains "$tmpdir/adb.log" "127.0.0.1:5555 shell getprop ro.product.model" || return 1
  connect_attempts=$(cat "$tmpdir/connect.count" 2>/dev/null || printf '0')
  [ "$connect_attempts" = "2" ] || {
    TEST_FAILURE_REASON="expected 2 connect attempts, got $connect_attempts"
    return 1
  }
}

retries_remote_command_after_offline_error() {
  tmpdir=$(make_tempdir)
  sdk_root="$tmpdir/data"
  mkdir -p "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools"

  cat >"$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools/adb" <<'SH'
#!/bin/sh
count_file=${ADB_CONNECT_COUNT:?}
command_count_file=${ADB_COMMAND_COUNT:?}
log_file=${ADB_LOG:?}

case "${1-}" in
  kill-server|start-server)
    exit 0
    ;;
  connect)
    count=$(cat "$count_file" 2>/dev/null || printf '0')
    count=$((count + 1))
    printf '%s' "$count" >"$count_file"
    printf '%s\n' "connected to ${2-}" >&2
    exit 0
    ;;
  -s)
    shift
    serial=$1
    shift
    case "${1-}" in
      get-state)
        printf '%s\n' device
        exit 0
        ;;
      shell)
        command_count=$(cat "$command_count_file" 2>/dev/null || printf '0')
        command_count=$((command_count + 1))
        printf '%s' "$command_count" >"$command_count_file"
        if [ "$command_count" -lt 2 ]; then
          printf '%s\n' "error: device offline" >&2
          exit 1
        fi
        printf '%s\n' "$serial $*" >>"$log_file"
        printf '%s\n' "Pixel 8a"
        exit 0
        ;;
    esac
    ;;
esac

exit 0
SH
  chmod +x "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools/adb"

  cat >"$tmpdir/firewall" <<'SH'
#!/bin/sh
while [ "$#" -gt 0 ]; do
  [ "$1" = "--" ] && break
  shift
done
shift
exec "$@"
SH
  chmod +x "$tmpdir/firewall"

  ADB_LOG="$tmpdir/adb.log" ADB_CONNECT_COUNT="$tmpdir/connect.count" \
    ADB_COMMAND_COUNT="$tmpdir/command.count" run_cmd env \
    XDG_DATA_HOME="$sdk_root" PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    ADB_LOG="$tmpdir/adb.log" ADB_CONNECT_COUNT="$tmpdir/connect.count" \
    ADB_COMMAND_COUNT="$tmpdir/command.count" \
    "$ROOT_DIR/spells/wards/firewalled-adb" --serial 127.0.0.1:5555 -- shell getprop ro.product.model

  assert_success || return 1
  assert_output_contains "Pixel 8a" || return 1
  command_attempts=$(cat "$tmpdir/command.count" 2>/dev/null || printf '0')
  [ "$command_attempts" = "2" ] || {
    TEST_FAILURE_REASON="expected 2 command attempts, got $command_attempts"
    return 1
  }
  connect_attempts=$(cat "$tmpdir/connect.count" 2>/dev/null || printf '0')
  [ "$connect_attempts" = "2" ] || {
    TEST_FAILURE_REASON="expected reconnect after offline error, got $connect_attempts connect attempts"
    return 1
  }
}

run_test_case "firewalled-adb shows help" shows_help
run_test_case "firewalled-adb uses firewall and serial allowlist" outer_wrapper_uses_firewall_and_serial_allowlist
run_test_case "firewalled-adb version works without serial" version_without_serial_does_not_trip_linebreak_guard
run_test_case "firewalled-adb retries transient remote connect failures" retries_remote_connect_before_running_command
run_test_case "firewalled-adb reconnects after remote offline errors" retries_remote_command_after_offline_error

finish_tests
