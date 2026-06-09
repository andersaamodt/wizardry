#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_menu_shows_blackhole_on_macos() {
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
    WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin \
    WIZARDRY_VOICE_AUDIO_HAS_BLACKHOLE=0 \
    "$ROOT_DIR/spells/.arcana/voice-audio/voice-audio-menu"

  assert_success || return 1
  args=$(cat "$tmp/menu.log")
  case "$args" in
    *"Voice Audio:"*"[ ] BlackHole render reference%WIZARDRY_LOG_LEVEL=1 $ROOT_DIR/spells/.arcana/voice-audio/install-blackhole"*'Exit%kill -TERM $PPID'*) : ;;
    *)
      TEST_FAILURE_REASON="unexpected macOS voice audio menu options: $args"
      return 1
      ;;
  esac
}

test_menu_shows_pipewire_on_linux() {
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
    WIZARDRY_VOICE_AUDIO_UNAME_S=Linux \
    WIZARDRY_VOICE_AUDIO_HAS_PIPEWIRE=0 \
    "$ROOT_DIR/spells/.arcana/voice-audio/voice-audio-menu"

  assert_success || return 1
  args=$(cat "$tmp/menu.log")
  case "$args" in
    *"Voice Audio:"*"[ ] PipeWire render reference%WIZARDRY_LOG_LEVEL=1 $ROOT_DIR/spells/.arcana/voice-audio/install-pipewire"*'Exit%kill -TERM $PPID'*) : ;;
    *)
      TEST_FAILURE_REASON="unexpected Linux voice audio menu options: $args"
      return 1
      ;;
  esac
}

run_test_case "voice-audio-menu shows BlackHole on macOS" test_menu_shows_blackhole_on_macos
run_test_case "voice-audio-menu shows PipeWire on Linux" test_menu_shows_pipewire_on_linux

finish_tests
