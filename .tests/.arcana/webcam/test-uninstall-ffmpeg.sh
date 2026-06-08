#!/bin/sh
# Behavioral coverage for uninstall-ffmpeg.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/webcam/uninstall-ffmpeg"

test_uninstall_ffmpeg_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: uninstall-ffmpeg" || return 1
}

test_uninstall_ffmpeg_is_executable() {
  [ -x "$ROOT_DIR/$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_uninstall_ffmpeg_delegates_to_manage_system_command() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/webcam" "$tmpdir/core"
  cp "$ROOT_DIR/$target" "$tmpdir/webcam/uninstall-ffmpeg"

  cat > "$tmpdir/core/manage-system-command" <<'EOF'
#!/bin/sh
printf 'args=%s %s %s\n' "${1-}" "${2-}" "${3-}"
EOF
  chmod +x "$tmpdir/core/manage-system-command" "$tmpdir/webcam/uninstall-ffmpeg"

  run_cmd sh "$tmpdir/webcam/uninstall-ffmpeg"
  assert_success || return 1
  assert_output_contains "args=--uninstall ffmpeg ffmpeg" || return 1
}

run_test_case "uninstall-ffmpeg shows help" test_uninstall_ffmpeg_help
run_test_case "uninstall-ffmpeg is executable" test_uninstall_ffmpeg_is_executable
run_test_case "uninstall-ffmpeg delegates to manage-system-command" \
  test_uninstall_ffmpeg_delegates_to_manage_system_command

finish_tests
