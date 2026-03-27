#!/bin/sh
# Behavioral coverage for is-yt-dlp-installed spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/yt-dlp/is-yt-dlp-installed"

test_is_yt_dlp_installed_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_is_yt_dlp_installed_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_is_yt_dlp_installed_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

run_test_case "is-yt-dlp-installed spell exists" test_is_yt_dlp_installed_exists
run_test_case "is-yt-dlp-installed spell is executable" test_is_yt_dlp_installed_executable
run_test_case "is-yt-dlp-installed spell --help is callable" test_is_yt_dlp_installed_help_callable

finish_tests
