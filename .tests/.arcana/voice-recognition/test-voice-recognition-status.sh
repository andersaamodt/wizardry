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

test_status_not_installed() {
  tmp=$(make_tempdir)
  run_cmd env \
    WIZARDRY_VOICE_RECOGNITION_DIR="$tmp/voice" \
    "$ROOT_DIR/spells/.arcana/voice-recognition/voice-recognition-status"
  assert_success || return 1
  assert_output_contains "not installed" || return 1
}

test_status_partial_when_optional_missing() {
  tmp=$(make_tempdir)
  root="$tmp/voice"
  make_component_install "$root" faster-whisper

  run_cmd env \
    WIZARDRY_VOICE_RECOGNITION_DIR="$root" \
    WIZARDRY_VOICE_UNAME_S=Darwin \
    WIZARDRY_VOICE_UNAME_M=arm64 \
    "$ROOT_DIR/spells/.arcana/voice-recognition/voice-recognition-status"
  assert_success || return 1
  assert_output_contains "partial install" || return 1
}

test_status_installed_when_all_available_are_ready() {
  tmp=$(make_tempdir)
  root="$tmp/voice"
  make_component_install "$root" faster-whisper
  make_component_install "$root" mlx-whisper

  run_cmd env \
    WIZARDRY_VOICE_RECOGNITION_DIR="$root" \
    WIZARDRY_VOICE_UNAME_S=Darwin \
    WIZARDRY_VOICE_UNAME_M=arm64 \
    "$ROOT_DIR/spells/.arcana/voice-recognition/voice-recognition-status"
  assert_success || return 1
  assert_output_contains "installed" || return 1
}

run_test_case "voice-recognition-status shows not installed" test_status_not_installed
run_test_case "voice-recognition-status shows partial install when optional backend missing" test_status_partial_when_optional_missing
run_test_case "voice-recognition-status shows installed when available backends are ready" test_status_installed_when_all_available_are_ready

finish_tests
