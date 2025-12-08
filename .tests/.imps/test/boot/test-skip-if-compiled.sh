#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_skip_when_compiled() {
  # Set compiled flag
  WIZARDRY_TEST_COMPILED=1
  export WIZARDRY_TEST_COMPILED
  
  # Source and call the function
  . "$test_root/spells/.imps/test/boot/skip-if-compiled"
  _skip_if_compiled
  result=$?
  
  [ "$result" = "222" ] || return 1
}

test_run_when_uncompiled() {
  # Unset compiled flag
  WIZARDRY_TEST_COMPILED=0
  export WIZARDRY_TEST_COMPILED
  
  # Source and call the function
  . "$test_root/spells/.imps/test/boot/skip-if-compiled"
  _skip_if_compiled
  result=$?
  
  [ "$result" = "0" ] || return 1
}

_run_test_case "skips when compiled" test_skip_when_compiled
_run_test_case "runs when uncompiled" test_run_when_uncompiled
_finish_tests
