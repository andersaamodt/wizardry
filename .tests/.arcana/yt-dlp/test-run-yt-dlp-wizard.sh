#!/bin/sh
# Behavioral coverage for run-yt-dlp-wizard spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/yt-dlp/run-yt-dlp-wizard"

test_run_yt_dlp_wizard_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_run_yt_dlp_wizard_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_run_yt_dlp_wizard_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

run_test_case "run-yt-dlp-wizard spell exists" test_run_yt_dlp_wizard_exists
run_test_case "run-yt-dlp-wizard spell is executable" test_run_yt_dlp_wizard_executable
run_test_case "run-yt-dlp-wizard spell --help is callable" test_run_yt_dlp_wizard_help_callable

finish_tests
