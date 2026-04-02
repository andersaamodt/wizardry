#!/bin/sh
# Behavioral coverage for jq.conf requirements file.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/web/.requirements/jq.conf"

test_jq_conf_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing requirements file: $target"
    return 1
  }
}

test_jq_conf_nonempty() {
  [ -s "$target" ] || {
    TEST_FAILURE_REASON="requirements file empty: $target"
    return 1
  }
}

test_jq_conf_readable() {
  [ -r "$target" ] || {
    TEST_FAILURE_REASON="requirements file unreadable: $target"
    return 1
  }
}

run_test_case "jq.conf file exists" test_jq_conf_exists
run_test_case "jq.conf file has content" test_jq_conf_nonempty
run_test_case "jq.conf file is readable" test_jq_conf_readable

finish_tests
