#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_voice_status_help() {
  run_spell "spells/.arcana/voice/voice-status" --help
  assert_success || return 1
  assert_output_contains "Usage: voice-status"
}

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

run_test_case "voice-status shows help" test_voice_status_help
run_test_case "voice-status counts both submenus" \
  test_voice_status_counts_both_submenus
finish_tests
