#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

write_python3_stub() {
  stub_dir=$1
  cat >"$stub_dir/python3" <<'SH'
#!/bin/sh
if [ "$1" = "-m" ] && [ "$2" = "venv" ] && [ -n "${3-}" ]; then
  target=$3
  mkdir -p "$target/bin"
  cat >"$target/bin/python" <<'PY'
#!/bin/sh
if [ "$1" = "-m" ] && [ "$2" = "ensurepip" ]; then
  exit 0
fi
if [ "$1" = "-m" ] && [ "$2" = "pip" ]; then
  exit 0
fi
cat >/dev/null
exit 0
PY
  chmod +x "$target/bin/python"
  exit 0
fi
exit 1
SH
  chmod +x "$stub_dir/python3"
}

write_ffmpeg_stub() {
  stub_dir=$1
  cat >"$stub_dir/ffmpeg" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$stub_dir/ffmpeg"
}

test_component_help() {
  run_spell "spells/.arcana/voice-recognition/voice-recognition-component" --help
  assert_success || return 1
  assert_output_contains "Usage: voice-recognition-component" || return 1
}

test_component_is_installed_false_when_missing() {
  tmp=$(make_tempdir)
  run_cmd env \
    WIZARDRY_VOICE_RECOGNITION_DIR="$tmp/voice" \
    "$ROOT_DIR/spells/.arcana/voice-recognition/voice-recognition-component" --is-installed faster-whisper
  assert_failure || return 1
}

test_component_enable_disable_faster_whisper() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stubs="$tmp/stubs"
  mkdir -p "$stubs"
  write_python3_stub "$stubs"
  write_ffmpeg_stub "$stubs"

  run_cmd env \
    PATH="$stubs:$PATH" \
    WIZARDRY_VOICE_RECOGNITION_DIR="$tmp/voice" \
    WIZARDRY_VOICE_UNAME_S=Linux \
    "$ROOT_DIR/spells/.arcana/voice-recognition/voice-recognition-component" --enable faster-whisper
  assert_success || return 1
  assert_path_exists "$tmp/voice/faster-whisper/installed" || return 1
  assert_path_exists "$tmp/voice/faster-whisper/venv/bin/python" || return 1

  run_cmd env \
    PATH="$stubs:$PATH" \
    WIZARDRY_VOICE_RECOGNITION_DIR="$tmp/voice" \
    "$ROOT_DIR/spells/.arcana/voice-recognition/voice-recognition-component" --is-installed faster-whisper
  assert_success || return 1

  run_cmd env \
    PATH="$stubs:$PATH" \
    WIZARDRY_VOICE_RECOGNITION_DIR="$tmp/voice" \
    "$ROOT_DIR/spells/.arcana/voice-recognition/voice-recognition-component" --disable faster-whisper
  assert_success || return 1
  assert_path_missing "$tmp/voice/faster-whisper" || return 1
}

test_component_rejects_mlx_outside_macos() {
  run_cmd env \
    WIZARDRY_VOICE_UNAME_S=Linux \
    "$ROOT_DIR/spells/.arcana/voice-recognition/voice-recognition-component" --enable mlx-whisper
  assert_failure || return 1
  assert_error_contains "requires macOS" || return 1
}

run_test_case "voice-recognition-component shows help" test_component_help
run_test_case "voice-recognition-component reports not installed when missing" test_component_is_installed_false_when_missing
run_test_case "voice-recognition-component enables and disables faster-whisper" test_component_enable_disable_faster_whisper
run_test_case "voice-recognition-component rejects mlx-whisper on unsupported host" test_component_rejects_mlx_outside_macos

finish_tests
