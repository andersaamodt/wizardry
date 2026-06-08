#!/bin/sh
# Behavioral coverage for webcam-status.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/webcam/webcam-status"

test_webcam_status_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: webcam-status" || return 1
}

test_webcam_status_reports_not_installed() {
  tmpdir=$(make_tempdir)
  run_cmd env HOME="$tmpdir/home" PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "not installed" || return 1
}

test_webcam_status_reports_partial_when_only_one_tool_exists() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  cat > "$stub_dir/ffmpeg" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/ffmpeg"

  run_cmd env HOME="$tmpdir/home" PATH="$stub_dir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "partial" || return 1
}

test_webcam_status_reports_ready_when_both_tools_exist() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  cat > "$stub_dir/ffmpeg" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat > "$stub_dir/go2rtc" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/ffmpeg" "$stub_dir/go2rtc"

  run_cmd env HOME="$tmpdir/home" PATH="$stub_dir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "ready" || return 1
}

run_test_case "webcam-status shows help" test_webcam_status_help
run_test_case "webcam-status reports not installed" test_webcam_status_reports_not_installed
run_test_case "webcam-status reports partial when one tool exists" \
  test_webcam_status_reports_partial_when_only_one_tool_exists
run_test_case "webcam-status reports ready when both tools exist" \
  test_webcam_status_reports_ready_when_both_tools_exist

finish_tests
