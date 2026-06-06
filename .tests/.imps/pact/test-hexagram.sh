#!/bin/sh
# Behavioral cases for hexagram:
# - runs a command in a clean HOME
# - preserves nonzero command status

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

hexagram_cleans_home() {
  run_spell "spells/.imps/pact/hexagram" sh -c 'case "$HOME" in "$OLD_HOME") exit 1 ;; esac; test -d "$HOME"'
  assert_success || return 1
}

hexagram_preserves_failure() {
  run_spell "spells/.imps/pact/hexagram" sh -c 'exit 7'
  [ "$STATUS" -eq 7 ] || {
    TEST_FAILURE_REASON="expected status 7, got $STATUS"
    return 1
  }
}

run_test_case "hexagram runs with clean HOME" hexagram_cleans_home
run_test_case "hexagram preserves failure status" hexagram_preserves_failure

finish_tests
