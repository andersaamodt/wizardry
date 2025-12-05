#!/bin/sh
# Test make-fixture imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_fixture() {
  fixture=$(_make_fixture)
  [ -d "$fixture" ]
}

test_creates_bin_dir() {
  fixture=$(_make_fixture)
  [ -d "$fixture/bin" ]
}

test_creates_log_dir() {
  fixture=$(_make_fixture)
  [ -d "$fixture/log" ]
}

test_creates_home_dir() {
  fixture=$(_make_fixture)
  [ -d "$fixture/home/.local/bin" ]
}

_run_test_case "make-fixture creates fixture directory" test_creates_fixture
_run_test_case "make-fixture creates bin directory" test_creates_bin_dir
_run_test_case "make-fixture creates log directory" test_creates_log_dir
_run_test_case "make-fixture creates home/.local/bin directory" test_creates_home_dir

_finish_tests
