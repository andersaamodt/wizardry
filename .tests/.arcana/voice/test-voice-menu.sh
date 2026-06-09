#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_voice_menu_help() {
  run_spell "spells/.arcana/voice/voice-menu" --help
  assert_success || return 1
  assert_output_contains "Usage: voice-menu"
}

test_voice_menu_contains_voice_submenus() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-require-command "$tmp"
  stub-exit-label "$tmp"

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/menu.log" \
    "$ROOT_DIR/spells/.arcana/voice/voice-menu"
  assert_success || return 1

  menu_args=$(cat "$tmp/menu.log" 2>/dev/null || printf '')
  case "$menu_args" in
    *"voice recognition%"*"/voice-recognition/voice-recognition-menu"*\
*"voice audio%"*"/voice-audio/voice-audio-menu"*)
      ;;
    *)
      TEST_FAILURE_REASON="voice-menu did not expose both voice submenus: $menu_args"
      return 1
      ;;
  esac
}

run_test_case "voice-menu shows help" test_voice_menu_help
run_test_case "voice-menu contains voice submenus" \
  test_voice_menu_contains_voice_submenus
finish_tests
