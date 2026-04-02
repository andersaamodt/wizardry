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

test_install_parakeet_help() {
  run_spell "spells/.arcana/voice-recognition/install-parakeet" --help
  assert_success || return 1
  assert_output_contains "Usage: install-parakeet" || return 1
}

test_install_parakeet_rejects_unsupported_host() {
  run_cmd env \
    WIZARDRY_VOICE_UNAME_S=Linux \
    WIZARDRY_VOICE_HAS_NVIDIA=0 \
    "$ROOT_DIR/spells/.arcana/voice-recognition/install-parakeet"
  assert_failure || return 1
  assert_error_contains "requires Linux with an NVIDIA GPU" || return 1
}

test_install_parakeet_installs_on_linux_nvidia() {
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
    WIZARDRY_VOICE_HAS_NVIDIA=1 \
    "$ROOT_DIR/spells/.arcana/voice-recognition/install-parakeet"
  assert_success || return 1
  assert_output_contains "installing parakeet" || return 1
  assert_path_exists "$tmp/voice/parakeet/installed" || return 1
  assert_path_exists "$tmp/voice/parakeet/venv/bin/python" || return 1
}

run_test_case "install-parakeet shows help" test_install_parakeet_help
run_test_case "install-parakeet rejects unsupported hosts" test_install_parakeet_rejects_unsupported_host
run_test_case "install-parakeet installs on Linux NVIDIA" test_install_parakeet_installs_on_linux_nvidia

finish_tests
