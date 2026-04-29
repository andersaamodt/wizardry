#!/bin/sh
# Test run-cmd imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_captures_stdout() {
  run_cmd printf "hello"
  [ "$OUTPUT" = "hello" ]
}

test_captures_exit_status() {
  run_cmd sh -c "exit 42"
  [ "$STATUS" -eq 42 ]
}

test_captures_stderr() {
  run_cmd sh -c 'printf "error" >&2'
  [ "$ERROR" = "error" ]
}

test_preserves_web_site_dir() {
  tmpdir=$(make_tempdir)
  site_dir="$tmpdir/site dir"
  mkdir -p "$site_dir"

  WEB_SITE_DIR="$site_dir" run_cmd sh -c 'printf "%s" "$WEB_SITE_DIR"'
  [ "$OUTPUT" = "$site_dir" ]
}

run_test_case "run-cmd captures stdout" test_captures_stdout
run_test_case "run-cmd captures exit status" test_captures_exit_status
run_test_case "run-cmd captures stderr" test_captures_stderr
run_test_case "run-cmd preserves WEB_SITE_DIR" test_preserves_web_site_dir

finish_tests
