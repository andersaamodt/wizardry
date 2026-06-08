#!/bin/sh
# Behavioral coverage for wizardry-audio-capture.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/voice-audio/wizardry-audio-capture"

test_audio_capture_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: wizardry-audio-capture" || return 1
}

test_audio_capture_status_json() {
  run_cmd env HOME="$WIZARDRY_TMPDIR/home" WIZARDRY_VOICE_AUDIO_UNAME_S=Linux \
    WIZARDRY_VOICE_AUDIO_HAS_PIPEWIRE=0 sh "$ROOT_DIR/$target" --status
  assert_success || return 1
  assert_output_contains '"platform"' || return 1
}

test_audio_capture_rejects_bad_duration() {
  run_cmd env HOME="$WIZARDRY_TMPDIR/home" sh "$ROOT_DIR/$target" \
    --mode mic --duration nope
  assert_failure || return 1
  assert_error_contains "duration must be a positive integer" || return 1
}

run_test_case "wizardry-audio-capture shows help" test_audio_capture_help
run_test_case "wizardry-audio-capture reports status JSON" test_audio_capture_status_json
run_test_case "wizardry-audio-capture rejects bad duration" test_audio_capture_rejects_bad_duration

finish_tests
