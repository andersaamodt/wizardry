#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_spell spells/wards/firewalled-termux --help
  assert_success || return 1
  assert_output_contains "Usage: firewalled-termux" || return 1
}

runs_payload_via_termux_intent_and_pulls_artifacts() {
  tmpdir=$(make_tempdir)
  payload="$tmpdir/payload.sh"

  cat >"$payload" <<'SH'
#!/bin/sh
printf 'termux payload:%s\n' "$1"
SH
  chmod +x "$payload"

  cat >"$tmpdir/firewalled-adb.in" <<'SH'
#!/bin/sh
set -eu

printf '%s\n' "$@" >>"__ADB_LOG__"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --)
      shift
      break
      ;;
    --serial|--allow)
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

stub_root=__STUB_ROOT__
mkdir -p "$stub_root"

map_remote_path() {
  printf '%s%s\n' "$stub_root" "$1"
}

case "$1" in
  push)
    src=$2
    dest=$(map_remote_path "$3")
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    ;;
  pull)
    src=$(map_remote_path "$2")
    dest=$3
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    ;;
  shell)
    shift
    case "$1" in
      am)
        launch_path=
        while [ "$#" -gt 0 ]; do
          case "$1" in
            --esa)
              if [ "${2-}" = "com.termux.RUN_COMMAND_ARGUMENTS" ]; then
                launch_path=${3-}
                break
              fi
              shift 3
              ;;
            *)
              shift
              ;;
          esac
        done
        [ -n "$launch_path" ] || exit 1
        remote_root=${launch_path%/launch.sh}
        payload=$(map_remote_path "$remote_root/payload.sh")
        args_file=$(map_remote_path "$remote_root/args.txt")
        results_dir=$(map_remote_path "$remote_root/results")
        mkdir -p "$results_dir"
        set --
        if [ -f "$args_file" ]; then
          while IFS= read -r arg || [ -n "$arg" ]; do
            set -- "$@" "$arg"
          done < "$args_file"
        fi
        if sh "$payload" "$@" >"$results_dir/stdout.txt" 2>"$results_dir/stderr.txt"; then
          payload_status=0
        else
          payload_status=$?
        fi
        printf '%s\n' "$payload_status" >"$results_dir/exit-code.txt"
        printf '%s\n' "Starting service: Intent { act=com.termux.RUN_COMMAND }"
        ;;
      test)
        target=$(map_remote_path "$3")
        [ -f "$target" ]
        ;;
      rm)
        target=$(map_remote_path "$3")
        rm -rf "$target"
        ;;
      *)
        exit 1
        ;;
    esac
    ;;
  *)
    exit 1
    ;;
esac
SH
  sed "s|__ADB_LOG__|$tmpdir/adb.log|g; s|__STUB_ROOT__|$tmpdir/device|g" "$tmpdir/firewalled-adb.in" >"$tmpdir/firewalled-adb"
  chmod +x "$tmpdir/firewalled-adb"

  run_cmd env PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    "$ROOT_DIR/spells/wards/firewalled-termux" --serial 127.0.0.1:5555 --allow 127.0.0.1:5555 -- "$payload" sample-arg

  assert_success || return 1
  assert_output_contains "termux payload:sample-arg" || return 1
  assert_file_contains "$tmpdir/adb.log" "com.termux.app.RunCommandService"
  assert_file_contains "$tmpdir/adb.log" "com.termux.RUN_COMMAND"
  assert_file_contains "$tmpdir/adb.log" "com.termux.RUN_COMMAND_PATH"
  assert_file_contains "$tmpdir/adb.log" "com.termux.RUN_COMMAND_ARGUMENTS"
  assert_file_contains "$tmpdir/adb.log" "com.termux.RUN_COMMAND_BACKGROUND"
}

propagates_payload_failure_status() {
  tmpdir=$(make_tempdir)
  payload="$tmpdir/payload.sh"

  cat >"$payload" <<'SH'
#!/bin/sh
printf '%s\n' "payload stdout"
printf '%s\n' "payload stderr" >&2
exit 7
SH
  chmod +x "$payload"

  cat >"$tmpdir/firewalled-adb.in" <<'SH'
#!/bin/sh
set -eu

while [ "$#" -gt 0 ]; do
  case "$1" in
    --)
      shift
      break
      ;;
    --serial|--allow)
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

stub_root=__STUB_ROOT__
map_remote_path() {
  printf '%s%s\n' "$stub_root" "$1"
}

case "$1" in
  push)
    dest=$(map_remote_path "$3")
    mkdir -p "$(dirname "$dest")"
    cp "$2" "$dest"
    ;;
  pull)
    src=$(map_remote_path "$2")
    mkdir -p "$(dirname "$3")"
    cp "$src" "$3"
    ;;
  shell)
    shift
    case "$1" in
      am)
        launch_path=
        while [ "$#" -gt 0 ]; do
          case "$1" in
            --esa)
              if [ "${2-}" = "com.termux.RUN_COMMAND_ARGUMENTS" ]; then
                launch_path=${3-}
                break
              fi
              shift 3
              ;;
            *)
              shift
              ;;
          esac
        done
        remote_root=${launch_path%/launch.sh}
        payload=$(map_remote_path "$remote_root/payload.sh")
        results_dir=$(map_remote_path "$remote_root/results")
        mkdir -p "$results_dir"
        if sh "$payload" >"$results_dir/stdout.txt" 2>"$results_dir/stderr.txt"; then
          payload_status=0
        else
          payload_status=$?
        fi
        printf '%s\n' "$payload_status" >"$results_dir/exit-code.txt"
        printf '%s\n' "Starting service: Intent { act=com.termux.RUN_COMMAND }"
        ;;
      test)
        [ -f "$(map_remote_path "$3")" ]
        ;;
      rm)
        rm -rf "$(map_remote_path "$3")"
        ;;
    esac
    ;;
esac
SH
  sed "s|__STUB_ROOT__|$tmpdir/device|g" "$tmpdir/firewalled-adb.in" >"$tmpdir/firewalled-adb"
  chmod +x "$tmpdir/firewalled-adb"

  run_cmd env PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    "$ROOT_DIR/spells/wards/firewalled-termux" -- "$payload"

  assert_status 7 || return 1
  assert_output_contains "payload stdout" || return 1
  assert_error_contains "payload stderr" || return 1
}

times_out_if_termux_never_writes_status() {
  tmpdir=$(make_tempdir)
  payload="$tmpdir/payload.sh"

  cat >"$payload" <<'SH'
#!/bin/sh
printf '%s\n' "never reached"
SH
  chmod +x "$payload"

  cat >"$tmpdir/firewalled-adb" <<'SH'
#!/bin/sh
set -eu

while [ "$#" -gt 0 ]; do
  case "$1" in
    --)
      shift
      break
      ;;
    --serial|--allow)
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

case "$1" in
  push)
    exit 0
    ;;
  pull)
    exit 1
    ;;
  shell)
    shift
    case "$1" in
      am)
        printf '%s\n' "Starting service: Intent { act=com.termux.RUN_COMMAND }"
        ;;
      test)
        exit 1
        ;;
      rm)
        exit 0
        ;;
    esac
    ;;
esac
SH
  chmod +x "$tmpdir/firewalled-adb"

  run_cmd env PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    "$ROOT_DIR/spells/wards/firewalled-termux" --timeout 1 -- "$payload"

  assert_status 1 || return 1
  assert_error_contains "timed out after 1 seconds" || return 1
}

times_out_if_pull_reports_success_without_status_artifact() {
  tmpdir=$(make_tempdir)
  payload="$tmpdir/payload.sh"

  cat >"$payload" <<'SH'
#!/bin/sh
printf '%s\n' "never reached"
SH
  chmod +x "$payload"

  cat >"$tmpdir/firewalled-adb" <<'SH'
#!/bin/sh
set -eu

while [ "$#" -gt 0 ]; do
  case "$1" in
    --)
      shift
      break
      ;;
    --serial|--allow)
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

case "$1" in
  push)
    exit 0
    ;;
  pull)
    exit 0
    ;;
  shell)
    shift
    case "$1" in
      am)
        printf '%s\n' "Starting service: Intent { act=com.termux.RUN_COMMAND }"
        ;;
      rm)
        exit 0
        ;;
    esac
    ;;
esac
SH
  chmod +x "$tmpdir/firewalled-adb"

  run_cmd env PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    "$ROOT_DIR/spells/wards/firewalled-termux" --timeout 1 -- "$payload"

  assert_status 1 || return 1
  assert_error_contains "timed out after 1 seconds" || return 1
}

falls_back_to_typed_termux_launch_when_intent_is_denied() {
  tmpdir=$(make_tempdir)
  payload="$tmpdir/payload.sh"

  cat >"$payload" <<'SH'
#!/bin/sh
printf '%s\n' "typed fallback worked"
SH
  chmod +x "$payload"

  cat >"$tmpdir/firewalled-adb.in" <<'SH'
#!/bin/sh
set -eu

printf '%s\n' "$@" >>"__ADB_LOG__"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --)
      shift
      break
      ;;
    --serial|--allow)
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

stub_root=__STUB_ROOT__
mkdir -p "$stub_root"

map_remote_path() {
  printf '%s%s\n' "$stub_root" "$1"
}

run_payload_from_launch() {
  launch_path=$1
  remote_root=${launch_path%/launch.sh}
  payload=$(map_remote_path "$remote_root/payload.sh")
  args_file=$(map_remote_path "$remote_root/args.txt")
  results_dir=$(map_remote_path "$remote_root/results")
  mkdir -p "$results_dir"
  set --
  if [ -f "$args_file" ]; then
    while IFS= read -r arg || [ -n "$arg" ]; do
      set -- "$@" "$arg"
    done < "$args_file"
  fi
  if sh "$payload" "$@" >"$results_dir/stdout.txt" 2>"$results_dir/stderr.txt"; then
    payload_status=0
  else
    payload_status=$?
  fi
  printf '%s\n' "$payload_status" >"$results_dir/exit-code.txt"
}

case "$1" in
  push)
    src=$2
    dest=$(map_remote_path "$3")
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    ;;
  pull)
    src=$(map_remote_path "$2")
    dest=$3
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    ;;
  shell)
    shift
    case "$1" in
      am)
        printf '%s\n' "Error: Requires permission com.termux.permission.RUN_COMMAND" >&2
        exit 1
        ;;
      input)
        case "${2-} ${3-}" in
          "text sh%s/sdcard/wt/r"*)
            typed_launch=${3#sh%s}
            printf '%s\n' "$typed_launch" >"$stub_root/typed-launch-path"
            ;;
          "keyevent ENTER")
            if [ -f "$stub_root/typed-launch-path" ]; then
              run_payload_from_launch "$(cat "$stub_root/typed-launch-path")"
            fi
            ;;
        esac
        ;;
      monkey)
        exit 0
        ;;
      test)
        target=$(map_remote_path "$3")
        [ -f "$target" ]
        ;;
      rm)
        target=$(map_remote_path "$3")
        rm -rf "$target"
        ;;
      *)
        exit 1
        ;;
    esac
    ;;
  *)
    exit 1
    ;;
esac
SH
  sed "s|__ADB_LOG__|$tmpdir/adb.log|g; s|__STUB_ROOT__|$tmpdir/device|g" "$tmpdir/firewalled-adb.in" >"$tmpdir/firewalled-adb"
  chmod +x "$tmpdir/firewalled-adb"

  run_cmd env PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    "$ROOT_DIR/spells/wards/firewalled-termux" -- "$payload"

  assert_success || return 1
  assert_output_contains "typed fallback worked" || return 1
  assert_file_contains "$tmpdir/adb.log" "sh%s/sdcard/wt/r"
  assert_file_contains "$tmpdir/adb.log" "ENTER" || return 1
  if grep -q 'force-stop com.termux' "$tmpdir/adb.log"; then
    TEST_FAILURE_REASON="typed fallback must not kill existing Termux sessions"
    return 1
  fi
}

falls_back_to_typed_termux_launch_when_intent_denial_is_only_on_stderr() {
  tmpdir=$(make_tempdir)
  payload="$tmpdir/payload.sh"

  cat >"$payload" <<'SH'
#!/bin/sh
printf '%s\n' "typed fallback worked from stderr-only denial"
SH
  chmod +x "$payload"

  cat >"$tmpdir/firewalled-adb.in" <<'SH'
#!/bin/sh
set -eu

printf '%s\n' "$@" >>"__ADB_LOG__"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --)
      shift
      break
      ;;
    --serial|--allow)
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

stub_root=__STUB_ROOT__
mkdir -p "$stub_root"

map_remote_path() {
  printf '%s%s\n' "$stub_root" "$1"
}

run_payload_from_launch() {
  launch_path=$1
  remote_root=${launch_path%/launch.sh}
  payload=$(map_remote_path "$remote_root/payload.sh")
  args_file=$(map_remote_path "$remote_root/args.txt")
  results_dir=$(map_remote_path "$remote_root/results")
  mkdir -p "$results_dir"
  set --
  if [ -f "$args_file" ]; then
    while IFS= read -r arg || [ -n "$arg" ]; do
      set -- "$@" "$arg"
    done < "$args_file"
  fi
  if sh "$payload" "$@" >"$results_dir/stdout.txt" 2>"$results_dir/stderr.txt"; then
    payload_status=0
  else
    payload_status=$?
  fi
  printf '%s\n' "$payload_status" >"$results_dir/exit-code.txt"
}

case "$1" in
  push)
    src=$2
    dest=$(map_remote_path "$3")
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    ;;
  pull)
    src=$(map_remote_path "$2")
    dest=$3
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    ;;
  shell)
    shift
    case "$1" in
      am)
        printf '%s\n' "Starting service: Intent { act=com.termux.RUN_COMMAND }"
        printf '%s\n' "Error: Requires permission com.termux.permission.RUN_COMMAND" >&2
        exit 0
        ;;
      input)
        case "${2-} ${3-}" in
          "text sh%s/sdcard/wt/r"*)
            typed_launch=${3#sh%s}
            printf '%s\n' "$typed_launch" >"$stub_root/typed-launch-path"
            ;;
          "keyevent ENTER")
            if [ -f "$stub_root/typed-launch-path" ]; then
              run_payload_from_launch "$(cat "$stub_root/typed-launch-path")"
            fi
            ;;
        esac
        ;;
      monkey)
        exit 0
        ;;
      rm)
        target=$(map_remote_path "$3")
        rm -rf "$target"
        ;;
      *)
        exit 1
        ;;
    esac
    ;;
  *)
    exit 1
    ;;
esac
SH
  sed "s|__ADB_LOG__|$tmpdir/adb.log|g; s|__STUB_ROOT__|$tmpdir/device|g" "$tmpdir/firewalled-adb.in" >"$tmpdir/firewalled-adb"
  chmod +x "$tmpdir/firewalled-adb"

  run_cmd env PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    "$ROOT_DIR/spells/wards/firewalled-termux" -- "$payload"

  assert_success || return 1
  assert_output_contains "typed fallback worked from stderr-only denial" || return 1
  assert_file_contains "$tmpdir/adb.log" "sh%s/sdcard/wt/r"
  assert_file_contains "$tmpdir/adb.log" "ENTER"
}

run_test_case "firewalled-termux shows help" shows_help
run_test_case "firewalled-termux runs payload via Termux intent and pulls artifacts" runs_payload_via_termux_intent_and_pulls_artifacts
run_test_case "firewalled-termux propagates payload failure status" propagates_payload_failure_status
run_test_case "firewalled-termux times out if Termux never writes status" times_out_if_termux_never_writes_status
run_test_case "firewalled-termux ignores empty successful pulls for missing status files" \
  times_out_if_pull_reports_success_without_status_artifact
run_test_case "firewalled-termux falls back to typed launch when intent is denied" falls_back_to_typed_termux_launch_when_intent_is_denied
run_test_case "firewalled-termux falls back when intent denial only appears on stderr" \
  falls_back_to_typed_termux_launch_when_intent_denial_is_only_on_stderr

finish_tests
