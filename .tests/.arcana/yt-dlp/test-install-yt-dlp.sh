#!/bin/sh
# Behavioral coverage for install-yt-dlp spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/yt-dlp/install-yt-dlp"

test_install_yt_dlp_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_install_yt_dlp_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_install_yt_dlp_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

run_test_case "install-yt-dlp spell exists" test_install_yt_dlp_exists
run_test_case "install-yt-dlp spell is executable" test_install_yt_dlp_executable
run_test_case "install-yt-dlp spell --help is callable" test_install_yt_dlp_help_callable

finish_tests
