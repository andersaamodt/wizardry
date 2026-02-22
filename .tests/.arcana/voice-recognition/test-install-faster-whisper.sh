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

test_install_faster_whisper_help() {
  run_spell "spells/.arcana/voice-recognition/install-faster-whisper" --help
  assert_success || return 1
  assert_output_contains "Usage: install-faster-whisper" || return 1
}

test_install_faster_whisper_installs_runtime() {
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
    "$ROOT_DIR/spells/.arcana/voice-recognition/install-faster-whisper"
  assert_success || return 1
  assert_output_contains "installing faster-whisper" || return 1
  assert_path_exists "$tmp/voice/faster-whisper/installed" || return 1
  assert_path_exists "$tmp/voice/faster-whisper/venv/bin/python" || return 1
}

run_test_case "install-faster-whisper shows help" test_install_faster_whisper_help
run_test_case "install-faster-whisper installs local runtime" test_install_faster_whisper_installs_runtime

finish_tests
