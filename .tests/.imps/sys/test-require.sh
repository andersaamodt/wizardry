#!/bin/sh
# Tests for the 'require' imp
# Comprehensive tests covering:
# - Basic delegation to require-command
# - REQUIRE_COMMAND override
# - Failure propagation
# - Multiple arguments handling
# - Edge cases (no args, empty message, special characters)

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"


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

test_require_propagates_exit_code() {
  tmp=$(make_tempdir)
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
exit 42
SH
  chmod +x "$tmp/require-command"
  run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.imps/sys/require" somecmd
  assert_status 42
}

test_require_multiple_arguments() {
  tmp=$(make_tempdir)
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
# Output each argument on a separate line to verify they're all passed
for arg in "$@"; do
  printf 'arg: %s\n' "$arg"
done
exit 0
SH
  chmod +x "$tmp/require-command"
  run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.imps/sys/require" cmd "first message" "second message"
  assert_success
  assert_output_contains "arg: cmd"
  assert_output_contains "arg: first message"
  assert_output_contains "arg: second message"
}

test_require_command_only_no_message() {
  tmp=$(make_tempdir)
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf 'called with %d args: %s\n' "$#" "$*"
exit 0
SH
  chmod +x "$tmp/require-command"
  run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.imps/sys/require" justcmd
  assert_success
  assert_output_contains "called with 1 args: justcmd"
}

test_require_empty_require_command_uses_default() {
  tmp=$(make_tempdir)
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf 'default require-command used\n'
exit 0
SH
  chmod +x "$tmp/require-command"
  # Setting REQUIRE_COMMAND to empty string should fall back to require-command
  run_cmd env PATH="$tmp:$PATH" REQUIRE_COMMAND="" "$ROOT_DIR/spells/.imps/sys/require" cmd
  assert_success
  assert_output_contains "default require-command used"
}

test_require_preserves_special_characters() {
  tmp=$(make_tempdir)
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf 'message: %s\n' "$2"
exit 0
SH
  chmod +x "$tmp/require-command"
  run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.imps/sys/require" cmd "The 'menu' command needs \"special\" chars"
  assert_success
  assert_output_contains "The 'menu' command needs \"special\" chars"
}

run_test_case "require passes to require-command" test_require_passes_to_require_command
run_test_case "require honors REQUIRE_COMMAND override" test_require_honors_require_command_override
run_test_case "require propagates failure from require-command" test_require_propagates_failure
run_test_case "require propagates exact exit code" test_require_propagates_exit_code
run_test_case "require handles multiple arguments" test_require_multiple_arguments
run_test_case "require works with command only, no message" test_require_command_only_no_message
run_test_case "require falls back to default when REQUIRE_COMMAND empty" test_require_empty_require_command_uses_default
run_test_case "require preserves special characters in messages" test_require_preserves_special_characters

# Tests for fallback behavior when require-command is not available
test_require_fallback_success() {
  tmp=$(make_tempdir)
  # Create a command that exists
  cat >"$tmp/existing-cmd" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/existing-cmd"
  # Run with PATH that has the command but NOT require-command
  run_cmd env PATH="$tmp" "$ROOT_DIR/spells/.imps/sys/require" existing-cmd
  assert_success
}

test_require_fallback_failure_with_message() {
  tmp=$(make_tempdir)
  # Run with empty PATH (no require-command, no target command)
  run_cmd env PATH="$tmp" "$ROOT_DIR/spells/.imps/sys/require" nonexistent-cmd "Custom error message"
  assert_failure
  assert_error_contains "Custom error message"
}

test_require_fallback_failure_default_message() {
  tmp=$(make_tempdir)
  # Run with empty PATH (no require-command, no target command, no custom message)
  run_cmd env PATH="$tmp" "$ROOT_DIR/spells/.imps/sys/require" nonexistent-cmd
  assert_failure
  assert_error_contains "require: missing required command 'nonexistent-cmd'"
}

test_require_fallback_shows_install_hint() {
  tmp=$(make_tempdir)
  run_cmd env PATH="$tmp" "$ROOT_DIR/spells/.imps/sys/require" missing-tool
  assert_failure
  assert_error_contains "install-menu"
}

run_test_case "require fallback succeeds when command exists" test_require_fallback_success
run_test_case "require fallback shows custom error message" test_require_fallback_failure_with_message
run_test_case "require fallback shows default error message" test_require_fallback_failure_default_message
run_test_case "require fallback shows install hint" test_require_fallback_shows_install_hint

finish_tests
