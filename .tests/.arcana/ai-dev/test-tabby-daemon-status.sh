#!/bin/sh
# Behavioral coverage for tabby-daemon-status spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/ai-dev/tabby-daemon-status"

test_tabby_daemon_status_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_tabby_daemon_status_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_tabby_daemon_status_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

run_test_case "tabby-daemon-status spell exists" test_tabby_daemon_status_exists
run_test_case "tabby-daemon-status spell is executable" test_tabby_daemon_status_executable
run_test_case "tabby-daemon-status spell --help is callable" test_tabby_daemon_status_help_callable

finish_tests
