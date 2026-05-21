#!/bin/sh
# Behavioral coverage for is-ffmpeg-installed.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/webcam/is-ffmpeg-installed"

test_is_ffmpeg_installed_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: is-ffmpeg-installed" || return 1
}

test_is_ffmpeg_installed_fails_without_binary() {
  tmpdir=$(make_tempdir)
  run_cmd env PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" sh "$ROOT_DIR/$target"
  assert_failure || return 1
}

test_is_ffmpeg_installed_succeeds_with_binary_on_path() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  cat > "$stub_dir/ffmpeg" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/ffmpeg"

  run_cmd env PATH="$stub_dir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" sh "$ROOT_DIR/$target"
  assert_success || return 1
}

run_test_case "is-ffmpeg-installed shows help" test_is_ffmpeg_installed_help
run_test_case "is-ffmpeg-installed fails without ffmpeg" \
  test_is_ffmpeg_installed_fails_without_binary
run_test_case "is-ffmpeg-installed succeeds with ffmpeg on PATH" \
  test_is_ffmpeg_installed_succeeds_with_binary_on_path

finish_tests
