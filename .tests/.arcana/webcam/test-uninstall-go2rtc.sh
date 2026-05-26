#!/bin/sh
# Behavioral coverage for uninstall-go2rtc.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/webcam/uninstall-go2rtc"

test_uninstall_go2rtc_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: uninstall-go2rtc" || return 1
}

test_uninstall_go2rtc_removes_user_local_binary() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/home/.local/bin"
  printf '%s\n' '#!/bin/sh' > "$tmpdir/home/.local/bin/go2rtc"
  chmod +x "$tmpdir/home/.local/bin/go2rtc"

  run_cmd env HOME="$tmpdir/home" sh "$ROOT_DIR/$target"
  assert_success || return 1
  [ ! -e "$tmpdir/home/.local/bin/go2rtc" ] || {
    TEST_FAILURE_REASON="uninstall-go2rtc left ~/.local/bin/go2rtc behind"
    return 1
  }
}

test_uninstall_go2rtc_succeeds_when_binary_missing() {
  tmpdir=$(make_tempdir)
  run_cmd env HOME="$tmpdir/home" sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "Removed user-local go2rtc" || return 1
}

run_test_case "uninstall-go2rtc shows help" test_uninstall_go2rtc_help
run_test_case "uninstall-go2rtc removes the user-local binary" \
  test_uninstall_go2rtc_removes_user_local_binary
run_test_case "uninstall-go2rtc succeeds when the binary is missing" \
  test_uninstall_go2rtc_succeeds_when_binary_missing

finish_tests
