#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

test_skip_when_compiled() {
  # Set compiled flag
  WIZARDRY_TEST_COMPILED=1
  export WIZARDRY_TEST_COMPILED
  
  # Should return skip code (222)
  . "$ROOT_DIR/spells/.imps/test/boot/skip-if-compiled"
  result=$?
  
  [ "$result" = "222" ] || return 1
}

test_run_when_uncompiled() {
  # Unset compiled flag
  WIZARDRY_TEST_COMPILED=0
  export WIZARDRY_TEST_COMPILED
  
  # Should return success (0)
  . "$ROOT_DIR/spells/.imps/test/boot/skip-if-compiled"
  result=$?
  
  [ "$result" = "0" ] || return 1
}

run_test_case "skips when compiled" test_skip_when_compiled
run_test_case "runs when uncompiled" test_run_when_uncompiled
finish_tests
