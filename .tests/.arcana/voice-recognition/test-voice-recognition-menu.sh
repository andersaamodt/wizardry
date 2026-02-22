#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_menu_help() {
  run_spell "spells/.arcana/voice-recognition/voice-recognition-menu" --help
  assert_success || return 1
  assert_output_contains "Usage: voice-recognition-menu" || return 1
}

test_menu_shows_macos_toggles() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-colors "$tmp"
  stub-require-command "$tmp"
  stub-exit-label "$tmp"

  run_cmd env \
    PATH="$tmp:$PATH" \
    MENU_LOG="$tmp/menu.log" \
    REQUIRE_LOG="$tmp/require.log" \
    WIZARDRY_VOICE_RECOGNITION_DIR="$tmp/voice" \
    WIZARDRY_VOICE_UNAME_S=Darwin \
    WIZARDRY_VOICE_UNAME_M=arm64 \
    WIZARDRY_VOICE_HAS_NVIDIA=0 \
    "$ROOT_DIR/spells/.arcana/voice-recognition/voice-recognition-menu"

  assert_success || return 1
  args=$(cat "$tmp/menu.log")
  case "$args" in
    *"Voice Recognition:"*"[ ] CTranslate2 Whisper%WIZARDRY_LOG_LEVEL=1 $ROOT_DIR/spells/.arcana/voice-recognition/install-ctranslate2-whisper"*"[ ] MLX-Whisper%WIZARDRY_LOG_LEVEL=1 $ROOT_DIR/spells/.arcana/voice-recognition/install-mlx-whisper"*'Exit%kill -TERM $PPID'*) : ;;
    *)
      TEST_FAILURE_REASON="unexpected macOS menu options: $args"
      return 1
      ;;
  esac
}

test_menu_shows_parakeet_toggle_on_linux_nvidia() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-colors "$tmp"
  stub-require-command "$tmp"
  stub-exit-label "$tmp"

  run_cmd env \
    PATH="$tmp:$PATH" \
    MENU_LOG="$tmp/menu.log" \
    REQUIRE_LOG="$tmp/require.log" \
    WIZARDRY_VOICE_RECOGNITION_DIR="$tmp/voice" \
    WIZARDRY_VOICE_UNAME_S=Linux \
    WIZARDRY_VOICE_HAS_NVIDIA=1 \
    "$ROOT_DIR/spells/.arcana/voice-recognition/voice-recognition-menu"

  assert_success || return 1
  args=$(cat "$tmp/menu.log")
  case "$args" in
    *"Voice Recognition:"*"[ ] CTranslate2 Whisper%WIZARDRY_LOG_LEVEL=1 $ROOT_DIR/spells/.arcana/voice-recognition/install-ctranslate2-whisper"*"[ ] Parakeet%WIZARDRY_LOG_LEVEL=1 $ROOT_DIR/spells/.arcana/voice-recognition/install-parakeet"*'Exit%kill -TERM $PPID'*) : ;;
    *)
      TEST_FAILURE_REASON="unexpected Linux NVIDIA menu options: $args"
      return 1
      ;;
  esac

  case "$args" in
    *"MLX-Whisper"*)
      TEST_FAILURE_REASON="MLX-Whisper should not appear on Linux"
      return 1
      ;;
  esac
}

run_test_case "voice-recognition-menu shows help" test_menu_help
run_test_case "voice-recognition-menu shows macOS toggles" test_menu_shows_macos_toggles
run_test_case "voice-recognition-menu shows Parakeet on Linux NVIDIA" test_menu_shows_parakeet_toggle_on_linux_nvidia

finish_tests
