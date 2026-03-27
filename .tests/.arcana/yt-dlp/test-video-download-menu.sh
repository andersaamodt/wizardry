#!/bin/sh
# Behavioral coverage for video-download-menu spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/yt-dlp/video-download-menu"

test_video_download_menu_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_video_download_menu_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_video_download_menu_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

run_test_case "video-download-menu spell exists" test_video_download_menu_exists
run_test_case "video-download-menu spell is executable" test_video_download_menu_executable
run_test_case "video-download-menu spell --help is callable" test_video_download_menu_help_callable

finish_tests
