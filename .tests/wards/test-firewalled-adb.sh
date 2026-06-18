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

write_fake_adb() {
  fake_adb_path=$1
  fake_log_path=$2
  cat >"$fake_adb_path.in" <<'SH'
#!/bin/sh
log_file=__ADB_LOG__
connect_count_file=${ADB_CONNECT_COUNT:-}
command_count_file=${ADB_COMMAND_COUNT:-}
state_count_file=${ADB_STATE_COUNT:-}

printf '%s\n' "$*" >>"$log_file"

if [ "${1-}" = "-L" ] && [ "${3-}" = "server" ] && [ "${4-}" = "nodaemon" ]; then
  exit 0
fi

if [ "${1-}" = "-P" ]; then
  shift 2
fi

case "${1-}" in
  kill-server)
    exit 0
    ;;
  connect)
    if [ -n "$connect_count_file" ]; then
      count=$(cat "$connect_count_file" 2>/dev/null || printf '0')
      count=$((count + 1))
      printf '%s' "$count" >"$connect_count_file"
      if [ -n "${ADB_FAIL_CONNECT_UNTIL:-}" ] && [ "$count" -lt "$ADB_FAIL_CONNECT_UNTIL" ]; then
        exit 1
      fi
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
        if [ -n "$state_count_file" ]; then
          state_count=$(cat "$state_count_file" 2>/dev/null || printf '0')
          state_count=$((state_count + 1))
          printf '%s' "$state_count" >"$state_count_file"
          if [ -n "${ADB_OFFLINE_STATE_UNTIL:-}" ] && [ "$state_count" -lt "$ADB_OFFLINE_STATE_UNTIL" ]; then
            printf '%s\n' offline
            exit 1
          fi
        fi
        if [ -n "$connect_count_file" ] && [ -n "${ADB_FAIL_CONNECT_UNTIL:-}" ]; then
          count=$(cat "$connect_count_file" 2>/dev/null || printf '0')
          [ "$count" -ge "$ADB_FAIL_CONNECT_UNTIL" ] || exit 1
        fi
        printf '%s\n' device
        exit 0
        ;;
      shell)
        if [ -n "$command_count_file" ]; then
          command_count=$(cat "$command_count_file" 2>/dev/null || printf '0')
          command_count=$((command_count + 1))
          printf '%s' "$command_count" >"$command_count_file"
          if [ "${ADB_FAIL_COMMAND_MODE:-}" = "offline-once" ] && [ "$command_count" -lt 2 ]; then
            printf '%s\n' "error: device offline" >&2
            exit 1
          fi
        fi
        if [ "${ADB_SHELL_STDOUT:-}" ]; then
          printf '%s\n' "$ADB_SHELL_STDOUT"
        fi
        printf '%s\n' "$serial $*" >>"$log_file"
        exit 0
        ;;
      push)
        if [ -n "$command_count_file" ]; then
          command_count=$(cat "$command_count_file" 2>/dev/null || printf '0')
          command_count=$((command_count + 1))
          printf '%s' "$command_count" >"$command_count_file"
          if [ "${ADB_FAIL_COMMAND_MODE:-}" = "copy-eof-once" ] && [ "$command_count" -lt 2 ]; then
            printf '%s\n' "adb: error: failed to read copy response: EOF" >&2
            exit 1
          fi
        fi
        printf '%s\n' "$serial $*" >>"$log_file"
        exit 0
        ;;
    esac
    ;;
esac

exit 0
SH
  sed "s|__ADB_LOG__|$fake_log_path|g" "$fake_adb_path.in" >"$fake_adb_path"
  chmod +x "$fake_adb_path"
}

outer_wrapper_uses_firewall_and_serial_allowlist() {
  tmpdir=$(make_tempdir)
  sdk_root="$tmpdir/data"
  mkdir -p "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools"

  write_fake_adb "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools/adb" "$tmpdir/adb.log"

  cat >"$tmpdir/firewall.in" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"__FIREWALL_LOG__"
while [ "$#" -gt 0 ]; do
  [ "$1" = "--" ] && break
  shift
done
shift
exec "$@"
SH
  sed "s|__FIREWALL_LOG__|$tmpdir/firewall.log|g" "$tmpdir/firewall.in" >"$tmpdir/firewall"
  chmod +x "$tmpdir/firewall"

  run_cmd env XDG_DATA_HOME="$sdk_root" PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    "$ROOT_DIR/spells/wards/firewalled-adb" --serial 127.0.0.1:5555 -- shell getprop ro.product.model

  assert_success || return 1
  assert_file_contains "$tmpdir/firewall.log" "--allow-localhost"
  assert_file_contains "$tmpdir/firewall.log" "127.0.0.1:5555"
  assert_file_contains "$tmpdir/adb.log" "-L tcp:localhost:"
  assert_file_contains "$tmpdir/adb.log" "connect 127.0.0.1:5555"
  assert_file_contains "$tmpdir/adb.log" "-P "
  assert_file_contains "$tmpdir/adb.log" "-s 127.0.0.1:5555 shell getprop ro.product.model"
}

version_without_serial_does_not_trip_linebreak_guard() {
  tmpdir=$(make_tempdir)
  sdk_root="$tmpdir/data"
  mkdir -p "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools"

  write_fake_adb "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools/adb" "$tmpdir/adb.log"

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

  run_cmd env XDG_DATA_HOME="$sdk_root" PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    "$ROOT_DIR/spells/wards/firewalled-adb" -- version

  assert_success || return 1
  assert_file_contains "$tmpdir/adb.log" "-L tcp:localhost:"
  assert_file_contains "$tmpdir/adb.log" "-P "
  assert_file_contains "$tmpdir/adb.log" "version"
}

retries_remote_connect_before_running_command() {
  tmpdir=$(make_tempdir)
  sdk_root="$tmpdir/data"
  mkdir -p "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools"

  write_fake_adb "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools/adb" "$tmpdir/adb.log"

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

  ADB_CONNECT_COUNT="$tmpdir/connect.count" run_cmd env \
    XDG_DATA_HOME="$sdk_root" PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    ADB_CONNECT_COUNT="$tmpdir/connect.count" \
    ADB_FAIL_CONNECT_UNTIL=2 \
    "$ROOT_DIR/spells/wards/firewalled-adb" --serial 127.0.0.1:5555 -- shell getprop ro.product.model

  assert_success || return 1
  assert_file_contains "$tmpdir/adb.log" "127.0.0.1:5555 shell getprop ro.product.model" || return 1
  connect_attempts=$(cat "$tmpdir/connect.count" 2>/dev/null || printf '0')
  [ "$connect_attempts" = "2" ] || {
    TEST_FAILURE_REASON="expected 2 connect attempts, got $connect_attempts"
    return 1
  }
}

waits_for_remote_transport_to_leave_offline_state() {
  tmpdir=$(make_tempdir)
  sdk_root="$tmpdir/data"
  mkdir -p "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools"

  write_fake_adb "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools/adb" "$tmpdir/adb.log"

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

  ADB_CONNECT_COUNT="$tmpdir/connect.count" ADB_STATE_COUNT="$tmpdir/state.count" run_cmd env \
    XDG_DATA_HOME="$sdk_root" PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    ADB_CONNECT_COUNT="$tmpdir/connect.count" \
    ADB_STATE_COUNT="$tmpdir/state.count" \
    ADB_OFFLINE_STATE_UNTIL=3 \
    ADB_SHELL_STDOUT="Pixel 8a" \
    "$ROOT_DIR/spells/wards/firewalled-adb" --serial 127.0.0.1:5555 -- shell getprop ro.product.model

  assert_success || return 1
  assert_output_contains "Pixel 8a" || return 1
  state_attempts=$(cat "$tmpdir/state.count" 2>/dev/null || printf '0')
  [ "$state_attempts" = "3" ] || {
    TEST_FAILURE_REASON="expected 3 state checks before ready, got $state_attempts"
    return 1
  }
}

retries_remote_command_after_offline_error() {
  tmpdir=$(make_tempdir)
  sdk_root="$tmpdir/data"
  mkdir -p "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools"

  write_fake_adb "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools/adb" "$tmpdir/adb.log"

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

  ADB_CONNECT_COUNT="$tmpdir/connect.count" ADB_COMMAND_COUNT="$tmpdir/command.count" run_cmd env \
    XDG_DATA_HOME="$sdk_root" PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    ADB_CONNECT_COUNT="$tmpdir/connect.count" \
    ADB_COMMAND_COUNT="$tmpdir/command.count" ADB_FAIL_COMMAND_MODE=offline-once \
    ADB_SHELL_STDOUT="Pixel 8a" \
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

retries_remote_command_after_copy_eof_error() {
  tmpdir=$(make_tempdir)
  sdk_root="$tmpdir/data"
  mkdir -p "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools"

  write_fake_adb "$sdk_root/theurgy/mobile-debugging/android-sdk/platform-tools/adb" "$tmpdir/adb.log"

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

  payload="$tmpdir/payload.txt"
  printf '%s\n' "payload" >"$payload"

  ADB_CONNECT_COUNT="$tmpdir/connect.count" ADB_COMMAND_COUNT="$tmpdir/command.count" run_cmd env \
    XDG_DATA_HOME="$sdk_root" PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    ADB_CONNECT_COUNT="$tmpdir/connect.count" \
    ADB_COMMAND_COUNT="$tmpdir/command.count" ADB_FAIL_COMMAND_MODE=copy-eof-once \
    "$ROOT_DIR/spells/wards/firewalled-adb" --serial 127.0.0.1:5555 -- push "$payload" /data/local/tmp/payload.txt

  assert_success || return 1
  command_attempts=$(cat "$tmpdir/command.count" 2>/dev/null || printf '0')
  [ "$command_attempts" = "2" ] || {
    TEST_FAILURE_REASON="expected 2 push attempts, got $command_attempts"
    return 1
  }
  connect_attempts=$(cat "$tmpdir/connect.count" 2>/dev/null || printf '0')
  [ "$connect_attempts" = "2" ] || {
    TEST_FAILURE_REASON="expected reconnect after copy EOF, got $connect_attempts connect attempts"
    return 1
  }
}

run_test_case "firewalled-adb shows help" shows_help
run_test_case "firewalled-adb uses firewall and serial allowlist" outer_wrapper_uses_firewall_and_serial_allowlist
run_test_case "firewalled-adb version works without serial" version_without_serial_does_not_trip_linebreak_guard
run_test_case "firewalled-adb retries transient remote connect failures" retries_remote_connect_before_running_command
run_test_case "firewalled-adb waits for remote transports to leave offline state" waits_for_remote_transport_to_leave_offline_state
run_test_case "firewalled-adb reconnects after remote offline errors" retries_remote_command_after_offline_error
run_test_case "firewalled-adb reconnects after copy EOF errors" retries_remote_command_after_copy_eof_error

finish_tests
