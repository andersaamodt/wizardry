#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_voice_menu_contains_voice_submenus() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-require-command "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" \
    "$ROOT_DIR/spells/.arcana/voice/voice-menu"
  assert_success || return 1

  menu_args=$(cat "$tmp/log" 2>/dev/null || printf '')
  case "$menu_args" in
    *"voice recognition%"*"/voice-recognition/voice-recognition-menu"*\
*"voice audio%"*"/voice-audio/voice-audio-menu"*)
      ;;
    *)
      TEST_FAILURE_REASON="voice-menu did not expose both voice submenus: $menu_args"
      return 1
      ;;
  esac
}

run_test_case "voice-menu contains voice submenus" \
  test_voice_menu_contains_voice_submenus

test_voice_status_counts_both_submenus() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir/voice" "$arcana_dir/voice-recognition" "$arcana_dir/voice-audio"
  cp "$ROOT_DIR/spells/.arcana/voice/voice-status" "$arcana_dir/voice/voice-status"
  chmod +x "$arcana_dir/voice/voice-status"

  cat >"$arcana_dir/voice-recognition/voice-recognition-status" <<'SH'
#!/bin/sh
printf '%s\n' 'installed'
SH
  chmod +x "$arcana_dir/voice-recognition/voice-recognition-status"

  cat >"$arcana_dir/voice-audio/voice-audio-status" <<'SH'
#!/bin/sh
printf '%s\n' 'not installed'
SH
  chmod +x "$arcana_dir/voice-audio/voice-audio-status"

  run_cmd env PATH="$PATH" "$arcana_dir/voice/voice-status"
  assert_success || return 1

  case "$OUTPUT" in
    *"partial install"*)
      ;;
    *)
      TEST_FAILURE_REASON="voice-status should count both child statuses: $OUTPUT"
      return 1
      ;;
  esac
}

run_test_case "voice-status counts both submenus" \
  test_voice_status_counts_both_submenus

finish_tests
