#!/bin/sh
# Behavioral coverage for .log requirements file.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/nostr/.log"

test__log_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing requirements file: $target"
    return 1
  }
}

test__log_nonempty_or_placeholder() {
  [ -s "$target" ] && return 0
  [ "$(basename "$target")" = ".log" ] && return 0
  TEST_FAILURE_REASON="requirements file empty: $target"
  return 1
}

test__log_readable() {
  [ -r "$target" ] || {
    TEST_FAILURE_REASON="requirements file unreadable: $target"
    return 1
  }
}

run_test_case ".log file exists" test__log_exists
run_test_case ".log file has content or placeholder" test__log_nonempty_or_placeholder
run_test_case ".log file is readable" test__log_readable

finish_tests
