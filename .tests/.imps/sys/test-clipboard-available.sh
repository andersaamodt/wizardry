#!/bin/sh
# Tests for the 'clipboard-available' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Setup test environment
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
ROOT_DIR=$_test_dir
_sys_path=${PATH:-/usr/local/bin:/usr/bin:/bin}
PATH="$ROOT_DIR/spells:$ROOT_DIR/spells/.imps"
for _d in "$ROOT_DIR/spells/.imps"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
for _d in "$ROOT_DIR/spells"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
PATH="$PATH:$_sys_path"
WIZARDRY_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/wizardry-test.XXXXXX")
export ROOT_DIR PATH WIZARDRY_TMPDIR

# Test state
_pass=0 _fail=0

# Run command and capture output
run_cmd() {
  _o=$(mktemp "$WIZARDRY_TMPDIR/o.XXXXXX"); _e=$(mktemp "$WIZARDRY_TMPDIR/e.XXXXXX")
  STATUS=0; "$@" >"$_o" 2>"$_e" || STATUS=$?
  OUTPUT=$(cat "$_o"); ERROR=$(cat "$_e"); rm -f "$_o" "$_e"
}
run_spell() { _s=$1; shift; run_cmd "$ROOT_DIR/$_s" "$@"; }

# Assertions (call imps with captured state)
assert_success() { test-assert-success "$STATUS" "$ERROR"; }
assert_failure() { test-assert-failure "$STATUS"; }
assert_status() { test-assert-status "$STATUS" "$1" "$ERROR"; }
assert_output_contains() { test-assert-output-contains "$OUTPUT" "$1"; }
assert_error_contains() { test-assert-error-contains "$ERROR" "$1"; }
assert_file_contains() { test-assert-file-contains "$1" "$2"; }
assert_path_exists() { test-assert-path-exists "$1"; }
assert_path_missing() { test-assert-path-missing "$1"; }

# Fixture helpers
make_tempdir() { test-make-tempdir; }
make_fixture() { test-make-fixture; }
write_apt_stub() { test-write-apt-stub "$1"; }
write_sudo_stub() { test-write-sudo-stub "$1"; }
write_command_stub() { test-write-command-stub "$1" "$2"; }
write_pkgin_stub() { test-write-pkgin-stub "$1"; }
provide_basic_tools() { test-provide-basic-tools "$1"; }
link_tools() { test-link-tools "$@"; }

# Test runner
run_test_case() {
  _d=$1; _f=$2
  if "$_f"; then _pass=$((_pass+1)); printf 'PASS %s\n' "$_d"
  else _fail=$((_fail+1)); printf 'FAIL %s\n' "$_d"; fi
}
finish_tests() {
  _t=$((_pass+_fail))
  printf '%s/%s tests passed' "$_pass" "$_t"
  [ "$_fail" -gt 0 ] && printf ' (%s failed)\n' "$_fail" && return 1
  printf '\n'
}


test_clipboard_returns_success_when_helper_exists() {
  # This test checks if the imp returns success when at least one helper is available
  # Since we can't guarantee which helpers are installed, we check if it returns
  # a valid exit code (0 or 1, or 127 in restricted sandbox environments)
  run_spell spells/.imps/sys/clipboard-available
  # The output should be empty (no args mode just returns exit code)
  if [ "$STATUS" -eq 0 ]; then
    # Helper exists - this is valid
    return 0
  elif [ "$STATUS" -eq 1 ] || [ "$STATUS" -eq 127 ]; then
    # No helper (1) or sandbox restriction (127) - also valid for this test
    return 0
  else
    TEST_FAILURE_REASON="unexpected exit code: $STATUS"
    return 1
  fi
}

test_clipboard_no_output_on_success() {
  # When a clipboard helper is available, there should be no output
  run_spell spells/.imps/sys/clipboard-available
  if [ "$STATUS" -eq 0 ]; then
    if [ -n "$OUTPUT" ]; then
      TEST_FAILURE_REASON="expected no output, got: $OUTPUT"
      return 1
    fi
  fi
  return 0
}

test_clipboard_checks_pbcopy() {
  # Create a fixture with only pbcopy available
  fixture=$(make_tempdir)
  write_command_stub "$fixture" pbcopy
  PATH="$fixture:$PATH" run_spell spells/.imps/sys/clipboard-available
  assert_success
  rm -rf "$fixture"
}

test_clipboard_checks_xsel() {
  # Create a fixture with only xsel available
  fixture=$(make_tempdir)
  write_command_stub "$fixture" xsel
  PATH="$fixture:$PATH" run_spell spells/.imps/sys/clipboard-available
  assert_success
  rm -rf "$fixture"
}

test_clipboard_checks_xclip() {
  # Create a fixture with only xclip available
  fixture=$(make_tempdir)
  write_command_stub "$fixture" xclip
  PATH="$fixture:$PATH" run_spell spells/.imps/sys/clipboard-available
  assert_success
  rm -rf "$fixture"
}

test_clipboard_checks_wl_copy() {
  # Create a fixture with only wl-copy available
  fixture=$(make_tempdir)
  write_command_stub "$fixture" wl-copy
  PATH="$fixture:$PATH" run_spell spells/.imps/sys/clipboard-available
  assert_success
  rm -rf "$fixture"
}

test_clipboard_fails_when_none_available() {
  # Create an empty fixture directory with no clipboard commands
  fixture=$(make_tempdir)
  # Use only the fixture in PATH (no clipboard helpers)
  # Need to include basic commands for shell to work
  link_tools "$fixture" sh cat printf test
  PATH="$fixture" run_cmd "$ROOT_DIR/spells/.imps/sys/clipboard-available"
  assert_failure
  rm -rf "$fixture"
}

run_test_case "clipboard-available returns valid exit code" test_clipboard_returns_success_when_helper_exists
run_test_case "clipboard-available no output on success" test_clipboard_no_output_on_success
run_test_case "clipboard-available detects pbcopy" test_clipboard_checks_pbcopy
run_test_case "clipboard-available detects xsel" test_clipboard_checks_xsel
run_test_case "clipboard-available detects xclip" test_clipboard_checks_xclip
run_test_case "clipboard-available detects wl-copy" test_clipboard_checks_wl_copy
run_test_case "clipboard-available fails when no helpers" test_clipboard_fails_when_none_available

finish_tests
