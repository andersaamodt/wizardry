#!/bin/sh
# Behavioral coverage for pandoc.conf requirements file.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/web/.requirements/pandoc.conf"

test_pandoc_conf_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing requirements file: $target"
    return 1
  }
}

test_pandoc_conf_nonempty() {
  [ -s "$target" ] || {
    TEST_FAILURE_REASON="requirements file empty: $target"
    return 1
  }
}

test_pandoc_conf_readable() {
  [ -r "$target" ] || {
    TEST_FAILURE_REASON="requirements file unreadable: $target"
    return 1
  }
}

run_test_case "pandoc.conf file exists" test_pandoc_conf_exists
run_test_case "pandoc.conf file has content" test_pandoc_conf_nonempty
run_test_case "pandoc.conf file is readable" test_pandoc_conf_readable

finish_tests
