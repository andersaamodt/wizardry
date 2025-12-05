#!/bin/sh
# Test provide-basic-tools imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_provides_tools() {
  fixture=$(_make_fixture)
  _provide_basic_tools "$fixture"
  # Check that at least cat is linked (should exist on all systems)
  [ -L "$fixture/bin/cat" ]
}

test_provides_sh() {
  fixture=$(_make_fixture)
  _provide_basic_tools "$fixture"
  [ -L "$fixture/bin/sh" ]
}

_run_test_case "provide-basic-tools links common tools" test_provides_tools
_run_test_case "provide-basic-tools links shell" test_provides_sh

_finish_tests
