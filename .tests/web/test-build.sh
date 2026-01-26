#!/bin/sh
# Tests for CGI build spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_build_help() {
  run_spell spells/web/build --help
  assert_success
  assert_output_contains "Usage: build"
}

run_test_case "build --help works" test_build_help

finish_tests
