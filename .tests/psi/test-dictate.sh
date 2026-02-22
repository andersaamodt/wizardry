#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

write_ffmpeg_stub() {
  stub_dir=$1
  cat >"$stub_dir/ffmpeg" <<'SH'
#!/bin/sh
out=''
for arg in "$@"; do
  out=$arg
done
[ -n "$out" ] || exit 1
printf 'RIFF' > "$out"
exit 0
SH
  chmod +x "$stub_dir/ffmpeg"
}

write_python_stub() {
  path=$1
  cat >"$path" <<'SH'
#!/bin/sh
cat >/dev/null
printf '%s\n' "stub dictated sentence"
SH
  chmod +x "$path"
}

test_dictate_help() {
  run_spell "spells/psi/dictate" --help
  assert_success || return 1
  assert_output_contains "Usage: dictate" || return 1
}

test_dictate_fails_without_backend() {
  tmp=$(make_tempdir)
  stubs="$tmp/stubs"
  mkdir -p "$stubs"
  write_ffmpeg_stub "$stubs"

  run_cmd env \
    PATH="$stubs:$PATH" \
    WIZARDRY_VOICE_RECOGNITION_DIR="$tmp/voice" \
    "$ROOT_DIR/spells/psi/dictate" --duration 1

  assert_failure || return 1
  assert_error_contains "no voice backend installed" || return 1
}

test_dictate_uses_backend_and_prints_text() {
  tmp=$(make_tempdir)
  stubs="$tmp/stubs"
  mkdir -p "$stubs"
  write_ffmpeg_stub "$stubs"

  python_stub="$tmp/python-stub"
  write_python_stub "$python_stub"

  voice_root="$tmp/voice"
  mkdir -p "$voice_root/faster-whisper/venv/bin"
  cp "$python_stub" "$voice_root/faster-whisper/venv/bin/python"
  chmod +x "$voice_root/faster-whisper/venv/bin/python"
  printf 'component=faster-whisper\n' > "$voice_root/faster-whisper/installed"

  run_cmd env \
    PATH="$stubs:$PATH" \
    WIZARDRY_VOICE_RECOGNITION_DIR="$voice_root" \
    WIZARDRY_VOICE_UNAME_S=Linux \
    WIZARDRY_VOICE_HAS_NVIDIA=0 \
    "$ROOT_DIR/spells/psi/dictate" --duration 1

  assert_success || return 1
  [ "$OUTPUT" = "stub dictated sentence" ] || {
    TEST_FAILURE_REASON="unexpected dictation output: $OUTPUT"
    return 1
  }
}

run_test_case "dictate shows help" test_dictate_help
run_test_case "dictate fails when backend is missing" test_dictate_fails_without_backend
run_test_case "dictate transcribes using backend command" test_dictate_uses_backend_and_prints_text

finish_tests
