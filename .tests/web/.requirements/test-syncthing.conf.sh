#!/bin/sh
# Behavioral coverage for syncthing.conf requirements file.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/web/.requirements/syncthing.conf"

test_syncthing_conf_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing requirements file: $target"
    return 1
  }
}

test_syncthing_conf_nonempty() {
  [ -s "$target" ] || {
    TEST_FAILURE_REASON="requirements file empty: $target"
    return 1
  }
}

test_syncthing_conf_readable() {
  [ -r "$target" ] || {
    TEST_FAILURE_REASON="requirements file unreadable: $target"
    return 1
  }
}

run_test_case "syncthing.conf file exists" test_syncthing_conf_exists
run_test_case "syncthing.conf file has content" test_syncthing_conf_nonempty
run_test_case "syncthing.conf file is readable" test_syncthing_conf_readable

finish_tests
