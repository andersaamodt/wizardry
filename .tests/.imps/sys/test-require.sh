#!/bin/sh
# Tests for the 'require' imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_require_help() {
  run_cmd "$ROOT_DIR/spells/.imps/sys/require" --help
  assert_success
  assert_error_contains "Usage: require COMMAND"
}

test_require_passes_to_require_command() {
  tmp=$(make_tempdir)
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf 'require-command called with: %s\n' "$*"
exit 0
SH
  chmod +x "$tmp/require-command"
  run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.imps/sys/require" testcmd "test message"
  assert_success
  assert_output_contains "require-command called with: testcmd test message"
}

test_require_honors_require_command_override() {
  tmp=$(make_tempdir)
  cat >"$tmp/my-require" <<'SH'
#!/bin/sh
printf 'my-require called with: %s\n' "$*"
exit 0
SH
  chmod +x "$tmp/my-require"
  run_cmd env PATH="$tmp:$PATH" REQUIRE_COMMAND="$tmp/my-require" "$ROOT_DIR/spells/.imps/sys/require" somecmd "message"
  assert_success
  assert_output_contains "my-require called with: somecmd message"
}

test_require_propagates_failure() {
  tmp=$(make_tempdir)
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf 'missing dependency\n' >&2
exit 1
SH
  chmod +x "$tmp/require-command"
  run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.imps/sys/require" missingcmd
  assert_failure
  assert_error_contains "missing dependency"
}

run_test_case "require --help shows usage" test_require_help
run_test_case "require passes to require-command" test_require_passes_to_require_command
run_test_case "require honors REQUIRE_COMMAND override" test_require_honors_require_command_override
run_test_case "require propagates failure from require-command" test_require_propagates_failure

finish_tests
