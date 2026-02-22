#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_component_install() {
  root=$1
  component=$2
  comp_dir="$root/$component"
  mkdir -p "$comp_dir/venv/bin"
  cat >"$comp_dir/venv/bin/python" <<'PY'
#!/bin/sh
exit 0
PY
  chmod +x "$comp_dir/venv/bin/python"
  printf 'component=%s\n' "$component" > "$comp_dir/installed"
}

test_backend_help() {
  run_spell "spells/.arcana/voice-recognition/voice-recognition-backend" --help
  assert_success || return 1
  assert_output_contains "Usage: voice-recognition-backend" || return 1
}

test_backend_prefers_mlx_on_macos() {
  tmp=$(make_tempdir)
  root="$tmp/voice"
  make_component_install "$root" faster-whisper
  make_component_install "$root" mlx-whisper

  run_cmd env \
    WIZARDRY_VOICE_RECOGNITION_DIR="$root" \
    WIZARDRY_VOICE_UNAME_S=Darwin \
    WIZARDRY_VOICE_UNAME_M=arm64 \
    "$ROOT_DIR/spells/.arcana/voice-recognition/voice-recognition-backend"

  assert_success || return 1
  [ "$OUTPUT" = "mlx-whisper" ] || {
    TEST_FAILURE_REASON="expected mlx-whisper, got: $OUTPUT"
    return 1
  }
}

test_backend_prefers_parakeet_on_linux_nvidia() {
  tmp=$(make_tempdir)
  root="$tmp/voice"
  make_component_install "$root" faster-whisper
  make_component_install "$root" parakeet

  run_cmd env \
    WIZARDRY_VOICE_RECOGNITION_DIR="$root" \
    WIZARDRY_VOICE_UNAME_S=Linux \
    WIZARDRY_VOICE_HAS_NVIDIA=1 \
    "$ROOT_DIR/spells/.arcana/voice-recognition/voice-recognition-backend"

  assert_success || return 1
  [ "$OUTPUT" = "parakeet" ] || {
    TEST_FAILURE_REASON="expected parakeet, got: $OUTPUT"
    return 1
  }
}

test_backend_falls_back_to_faster() {
  tmp=$(make_tempdir)
  root="$tmp/voice"
  make_component_install "$root" faster-whisper

  run_cmd env \
    WIZARDRY_VOICE_RECOGNITION_DIR="$root" \
    WIZARDRY_VOICE_UNAME_S=Linux \
    WIZARDRY_VOICE_HAS_NVIDIA=0 \
    "$ROOT_DIR/spells/.arcana/voice-recognition/voice-recognition-backend"

  assert_success || return 1
  [ "$OUTPUT" = "faster-whisper" ] || {
    TEST_FAILURE_REASON="expected faster-whisper, got: $OUTPUT"
    return 1
  }
}

test_backend_outputs_python_and_model() {
  tmp=$(make_tempdir)
  root="$tmp/voice"
  make_component_install "$root" faster-whisper

  run_cmd env \
    WIZARDRY_VOICE_RECOGNITION_DIR="$root" \
    WIZARDRY_VOICE_MODEL_FASTER=base.en \
    "$ROOT_DIR/spells/.arcana/voice-recognition/voice-recognition-backend" --python
  assert_success || return 1
  assert_output_contains "$root/faster-whisper/venv/bin/python" || return 1

  run_cmd env \
    WIZARDRY_VOICE_RECOGNITION_DIR="$root" \
    WIZARDRY_VOICE_MODEL_FASTER=base.en \
    "$ROOT_DIR/spells/.arcana/voice-recognition/voice-recognition-backend" --model
  assert_success || return 1
  [ "$OUTPUT" = "base.en" ] || {
    TEST_FAILURE_REASON="expected base.en model output, got: $OUTPUT"
    return 1
  }
}

test_backend_fails_when_missing() {
  tmp=$(make_tempdir)
  root="$tmp/voice"
  mkdir -p "$root"

  run_cmd env \
    WIZARDRY_VOICE_RECOGNITION_DIR="$root" \
    "$ROOT_DIR/spells/.arcana/voice-recognition/voice-recognition-backend"

  assert_failure || return 1
  assert_error_contains "no installed backend" || return 1
}

run_test_case "voice-recognition-backend shows help" test_backend_help
run_test_case "voice-recognition-backend prefers mlx on macOS" test_backend_prefers_mlx_on_macos
run_test_case "voice-recognition-backend prefers parakeet on Linux NVIDIA" test_backend_prefers_parakeet_on_linux_nvidia
run_test_case "voice-recognition-backend falls back to faster-whisper" test_backend_falls_back_to_faster
run_test_case "voice-recognition-backend outputs python and model" test_backend_outputs_python_and_model
run_test_case "voice-recognition-backend fails when none installed" test_backend_fails_when_missing

finish_tests
