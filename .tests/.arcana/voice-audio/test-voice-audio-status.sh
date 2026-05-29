#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_status_reports_blackhole_active() {
  run_cmd env \
    WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin \
    WIZARDRY_VOICE_AUDIO_HAS_BLACKHOLE=1 \
    "$ROOT_DIR/spells/.arcana/voice-audio/wizardry-audio-capture" --status
  assert_success || return 1
  assert_output_contains '"state":"active"' || return 1
}

test_status_points_macos_to_blackhole() {
  run_cmd env \
    WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin \
    WIZARDRY_VOICE_AUDIO_HAS_BLACKHOLE=0 \
    "$ROOT_DIR/spells/.arcana/voice-audio/wizardry-audio-capture" --status
  assert_success || return 1
  assert_output_contains '"installable":"blackhole"' || return 1
}

test_status_reports_pipewire_adapter() {
  run_cmd env \
    WIZARDRY_VOICE_AUDIO_UNAME_S=Linux \
    WIZARDRY_VOICE_AUDIO_HAS_PIPEWIRE=1 \
    WIZARDRY_VOICE_AUDIO_PIPEWIRE_RUNNING=1 \
    "$ROOT_DIR/spells/.arcana/voice-audio/wizardry-audio-capture" --status
  assert_success || return 1
  assert_output_contains '"adapter":"pipewire"' || return 1
}

test_status_reports_unsupported_platform() {
  run_cmd env \
    WIZARDRY_VOICE_AUDIO_UNAME_S=Plan9 \
    "$ROOT_DIR/spells/.arcana/voice-audio/wizardry-audio-capture" --status
  assert_success || return 1
  assert_output_contains '"supported":false' || return 1
}

run_test_case "voice audio status reports BlackHole active" test_status_reports_blackhole_active
run_test_case "voice audio status points macOS to BlackHole" test_status_points_macos_to_blackhole
run_test_case "voice audio status reports PipeWire adapter" test_status_reports_pipewire_adapter
run_test_case "voice audio status reports unsupported platform" test_status_reports_unsupported_platform

finish_tests
