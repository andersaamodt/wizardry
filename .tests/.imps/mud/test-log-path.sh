#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_log_path_moves_git_room_logs_to_xdg_state() {
  tmpdir=$(make_tempdir)
  test_home="$tmpdir/home"
  room_dir="$test_home/git/test-room"
  mkdir -p "$room_dir"
  printf '%s\n' "legacy" > "$room_dir/.log"

  log_path=$(HOME="$test_home" sh "$test_root/spells/.imps/mud/log-path" "$room_dir" 2>"$tmpdir/error")
  status=$?
  if [ "$status" -ne 0 ]; then
    TEST_FAILURE_REASON="log-path should succeed for an existing room directory"
    rm -rf "$tmpdir"
    return 1
  fi
  if [ -s "$tmpdir/error" ]; then
    TEST_FAILURE_REASON="log-path should not emit errors for a valid room directory"
    rm -rf "$tmpdir"
    return 1
  fi

  expected_root="$test_home/.local/state/wizardry/mud/logs"
  case "$log_path" in
    "$expected_root"/*.log) ;;
    *)
      TEST_FAILURE_REASON="log-path should redirect MUD logs into XDG state"
      rm -rf "$tmpdir"
      return 1
      ;;
  esac

  [ -f "$log_path" ] || {
    TEST_FAILURE_REASON="log-path should create or migrate the external log file"
    rm -rf "$tmpdir"
    return 1
  }
  [ ! -e "$room_dir/.log" ] || {
    TEST_FAILURE_REASON="legacy repo-local .log should be removed after migration"
    rm -rf "$tmpdir"
    return 1
  }
  grep -q '^legacy$' "$log_path" || {
    TEST_FAILURE_REASON="migrated log should preserve previous contents"
    rm -rf "$tmpdir"
    return 1
  }

  rm -rf "$tmpdir"
}

run_test_case "log-path redirects room logs into XDG state with migration" test_log_path_moves_git_room_logs_to_xdg_state
finish_tests
