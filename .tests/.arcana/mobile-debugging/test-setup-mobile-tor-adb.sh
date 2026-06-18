#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_cmd "$ROOT_DIR/spells/.arcana/mobile-debugging/setup-mobile-tor-adb" --help
  assert_success
  assert_output_contains "Usage: setup-mobile-tor-adb"
}

stages_script_through_firewalled_adb() {
  tmpdir=$(make_tempdir)

  cat >"$tmpdir/firewalled-adb" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"${ADB_LOG:?}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    push)
      shift
      cp "$1" "${PUSHED_SCRIPT_COPY:?}"
      exit 0
      ;;
    shell)
      shift
      case " $* " in
        *"wizardry-tor-adb-hostname.txt"*)
          printf '%s\n' abcdefghijklmnop.onion
          ;;
      esac
      exit 0
      ;;
  esac
  shift
done
exit 0
SH
  chmod +x "$tmpdir/firewalled-adb"

  ADB_LOG="$tmpdir/adb.log" PUSHED_SCRIPT_COPY="$tmpdir/pushed-script.sh" \
    run_cmd env PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    ADB_LOG="$tmpdir/adb.log" PUSHED_SCRIPT_COPY="$tmpdir/pushed-script.sh" \
    "$ROOT_DIR/spells/.arcana/mobile-debugging/setup-mobile-tor-adb" \
    --serial 192.168.1.159:34897 \
    --no-type-command

  assert_success || return 1
  assert_file_contains "$tmpdir/adb.log" "push"
  assert_file_contains "$tmpdir/adb.log" "/sdcard/Download/wizardry-tor-adb-setup.sh"
  assert_file_contains "$tmpdir/adb.log" "RunCommandService"
  assert_file_contains "$tmpdir/pushed-script.sh" 'launcher_script="$HOME/.termux/wizardry-tor-adb-start.sh"'
  assert_file_contains "$tmpdir/pushed-script.sh" "getprop service.adb.tcp.port"
  assert_file_contains "$tmpdir/pushed-script.sh" "getprop service.adb.tls.port"
  assert_file_contains "$tmpdir/pushed-script.sh" 'resolved_adb_target="127.0.0.1:$adb_port"'
  assert_file_contains "$tmpdir/pushed-script.sh" 'HiddenServicePort 5555 $resolved_adb_target'
  assert_file_contains "$tmpdir/pushed-script.sh" '/data/data/com.termux/files/home/.termux/wizardry-tor-adb-start.sh'
  assert_output_contains "firewalled-adb-tor --onion abcdefghijklmnop.onion:5555 -- devices"
}

rejects_bad_target() {
  run_cmd "$ROOT_DIR/spells/.arcana/mobile-debugging/setup-mobile-tor-adb" \
    --serial 192.168.1.159:34897 \
    --adb-target not-a-port \
    --no-type-command \
    --no-wait

  assert_failure
  assert_error_contains "HOST:PORT"
}

run_test_case "setup-mobile-tor-adb shows help" shows_help
run_test_case "setup-mobile-tor-adb stages script through firewalled adb" stages_script_through_firewalled_adb
run_test_case "setup-mobile-tor-adb rejects bad target" rejects_bad_target

finish_tests
