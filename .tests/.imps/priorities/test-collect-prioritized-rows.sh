#!/bin/sh
# Behavioral coverage for collect-prioritized-rows imp.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.imps/priorities/collect-prioritized-rows"

test_collect_prioritized_rows_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing imp: $target"
    return 1
  }
}

test_collect_prioritized_rows_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="imp not executable: $target"
    return 1
  }
}

test_collect_prioritized_rows_nonempty() {
  [ -s "$target" ] || {
    TEST_FAILURE_REASON="imp empty: $target"
    return 1
  }
}

run_test_case "collect-prioritized-rows imp exists" test_collect_prioritized_rows_exists
run_test_case "collect-prioritized-rows imp is executable" test_collect_prioritized_rows_executable
run_test_case "collect-prioritized-rows imp has content" test_collect_prioritized_rows_nonempty

finish_tests
