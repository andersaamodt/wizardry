#!/bin/sh
# Behavioral coverage for install-ffmpeg.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/webcam/install-ffmpeg"

test_install_ffmpeg_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: install-ffmpeg" || return 1
}

test_install_ffmpeg_is_executable() {
  [ -x "$ROOT_DIR/$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_install_ffmpeg_delegates_to_manage_system_command() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/webcam" "$tmpdir/core"
  cp "$ROOT_DIR/$target" "$tmpdir/webcam/install-ffmpeg"

  cat > "$tmpdir/core/manage-system-command" <<'EOF'
#!/bin/sh
printf 'force=%s\n' "${FORCE_INSTALL-}"
printf 'args=%s %s\n' "${1-}" "${2-}"
EOF
  chmod +x "$tmpdir/core/manage-system-command" "$tmpdir/webcam/install-ffmpeg"

  run_cmd env INSTALL_FFMPEG_FORCE_INSTALL=1 sh "$tmpdir/webcam/install-ffmpeg"
  assert_success || return 1
  assert_output_contains "force=1" || return 1
  assert_output_contains "args=ffmpeg ffmpeg" || return 1
}

run_test_case "install-ffmpeg shows help" test_install_ffmpeg_help
run_test_case "install-ffmpeg is executable" test_install_ffmpeg_is_executable
run_test_case "install-ffmpeg delegates to manage-system-command" \
  test_install_ffmpeg_delegates_to_manage_system_command

finish_tests
