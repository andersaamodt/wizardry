#!/bin/sh
# Behavioral coverage for cleanup-artificer-test-workspaces spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/ai-dev/cleanup-artificer-test-workspaces"

test_cleanup_artificer_test_workspaces_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_cleanup_artificer_test_workspaces_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_cleanup_artificer_test_workspaces_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

run_test_case "cleanup-artificer-test-workspaces spell exists" test_cleanup_artificer_test_workspaces_exists
run_test_case "cleanup-artificer-test-workspaces spell is executable" test_cleanup_artificer_test_workspaces_executable
run_test_case "cleanup-artificer-test-workspaces spell --help is callable" test_cleanup_artificer_test_workspaces_help_callable

finish_tests
