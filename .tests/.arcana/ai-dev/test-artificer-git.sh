#!/bin/sh
# Behavioral coverage for artificer-git spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/ai-dev/artificer-git"

test_artificer_git_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_artificer_git_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_artificer_git_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

run_test_case "artificer-git spell exists" test_artificer_git_exists
run_test_case "artificer-git spell is executable" test_artificer_git_executable
run_test_case "artificer-git spell --help is callable" test_artificer_git_help_callable

finish_tests
