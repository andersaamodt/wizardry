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
    WIZARDRY_VOICE_AUDIO_ROUTE_ACTIVE=1 \
    "$ROOT_DIR/spells/.arcana/voice-audio/wizardry-audio-capture" --status
  assert_success || return 1
  assert_output_contains '"state":"active"' || return 1
}

test_status_requires_playback_route() {
  run_cmd env \
    WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin \
    WIZARDRY_VOICE_AUDIO_HAS_BLACKHOLE=1 \
    WIZARDRY_VOICE_AUDIO_ROUTE_ACTIVE=0 \
    "$ROOT_DIR/spells/.arcana/voice-audio/wizardry-audio-capture" --status
  assert_success || return 1
  assert_output_contains '"state":"degraded"' || return 1
  assert_output_contains 'playback is not routed through Wizardry Playback Isolation' || return 1
}

test_status_points_macos_to_blackhole() {
  run_cmd env \
    WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin \
    WIZARDRY_VOICE_AUDIO_HAS_BLACKHOLE=0 \
    "$ROOT_DIR/spells/.arcana/voice-audio/wizardry-audio-capture" --status
  assert_success || return 1
  assert_output_contains '"installable":"blackhole"' || return 1
}

test_status_requires_visible_blackhole_capture() {
  tmp="${WIZARDRY_TMPDIR:-/tmp}/voice-audio-status-$$"
  mkdir -p "$tmp"
  cat > "$tmp/ffmpeg" <<'EOF'
#!/bin/sh
printf '%s\n' '[AVFoundation indev @ test] AVFoundation audio devices:' >&2
printf '%s\n' '[AVFoundation indev @ test] [0] USB CAMERA' >&2
exit 1
EOF
  chmod +x "$tmp/ffmpeg"
  run_cmd env \
    PATH="$tmp:$PATH" \
    WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin \
    "$ROOT_DIR/spells/.arcana/voice-audio/wizardry-audio-capture" --status
  assert_success || return 1
  assert_output_contains '"state":"degraded"' || return 1
  assert_output_contains 'no BlackHole capture device is visible yet' || return 1
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

test_capture_mic_stream_uses_ffmpeg() {
  tmp="${WIZARDRY_TMPDIR:-/tmp}/voice-audio-mic-$$"
  mkdir -p "$tmp"
  cat > "$tmp/ffmpeg" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" > "$WIZARDRY_TEST_FFMPEG_LOG"
out=''
for arg in "$@"; do out=$arg; done
printf '%s\n' 'RIFFtest' > "$out"
EOF
  chmod +x "$tmp/ffmpeg"
  run_cmd env \
    PATH="$tmp:$PATH" \
    WIZARDRY_TEST_FFMPEG_LOG="$tmp/ffmpeg.log" \
    WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin \
    sh "$ROOT_DIR/spells/.arcana/voice-audio/wizardry-audio-capture" --mode mic --duration 1 --output "$tmp/mic.wav"
  assert_success || return 1
  [ -f "$tmp/mic.wav" ] || {
    TEST_FAILURE_REASON="mic stream did not write output file"
    return 1
  }
  case "$(cat "$tmp/ffmpeg.log")" in
    *"-f avfoundation -i :0"*"-t 1"*) : ;;
    *)
      TEST_FAILURE_REASON="mic stream did not use expected ffmpeg capture arguments"
      return 1
      ;;
  esac
}

test_capture_render_stream_uses_blackhole() {
  tmp="${WIZARDRY_TMPDIR:-/tmp}/voice-audio-render-$$"
  mkdir -p "$tmp"
  cat > "$tmp/ffmpeg" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" > "$WIZARDRY_TEST_FFMPEG_LOG"
out=''
for arg in "$@"; do out=$arg; done
printf '%s\n' 'RIFFtest' > "$out"
EOF
  chmod +x "$tmp/ffmpeg"
  run_cmd env \
    PATH="$tmp:$PATH" \
    WIZARDRY_TEST_FFMPEG_LOG="$tmp/ffmpeg.log" \
    WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin \
    WIZARDRY_VOICE_AUDIO_HAS_BLACKHOLE=1 \
    sh "$ROOT_DIR/spells/.arcana/voice-audio/wizardry-audio-capture" --mode render --duration 1 --output "$tmp/render.wav"
  assert_success || return 1
  [ -f "$tmp/render.wav" ] || {
    TEST_FAILURE_REASON="render stream did not write output file"
    return 1
  }
  case "$(cat "$tmp/ffmpeg.log")" in
    *"-f avfoundation -i :BlackHole 2ch"*"-t 1"*) : ;;
    *)
      TEST_FAILURE_REASON="render stream did not use expected BlackHole ffmpeg arguments"
      return 1
      ;;
  esac
}

test_capture_render_stream_requires_reference() {
  tmp="${WIZARDRY_TMPDIR:-/tmp}/voice-audio-render-missing-$$"
  mkdir -p "$tmp"
  cat > "$tmp/ffmpeg" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$tmp/ffmpeg"
  run_cmd env \
    PATH="$tmp:$PATH" \
    WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin \
    WIZARDRY_VOICE_AUDIO_HAS_BLACKHOLE=0 \
    sh "$ROOT_DIR/spells/.arcana/voice-audio/wizardry-audio-capture" --mode render --duration 1 --output "$tmp/render.wav"
  [ "${STATUS:-0}" != 0 ] || {
    TEST_FAILURE_REASON="render stream succeeded without a render-reference adapter"
    return 1
  }
  case "${ERROR:-}" in
    *'render-reference capture is unavailable'*) : ;;
    *)
      TEST_FAILURE_REASON="render stream did not explain missing render-reference capture"
      return 1
      ;;
  esac
}

run_test_case "voice audio status reports BlackHole active" test_status_reports_blackhole_active
run_test_case "voice audio status requires playback route" test_status_requires_playback_route
run_test_case "voice audio status points macOS to BlackHole" test_status_points_macos_to_blackhole
run_test_case "voice audio status requires visible BlackHole capture" test_status_requires_visible_blackhole_capture
run_test_case "voice audio status reports PipeWire adapter" test_status_reports_pipewire_adapter
run_test_case "voice audio status reports unsupported platform" test_status_reports_unsupported_platform
run_test_case "voice audio mic stream uses ffmpeg" test_capture_mic_stream_uses_ffmpeg
run_test_case "voice audio render stream uses BlackHole" test_capture_render_stream_uses_blackhole
run_test_case "voice audio render stream requires reference" test_capture_render_stream_requires_reference

finish_tests
