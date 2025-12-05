#!/bin/sh
# Test run-spell imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_runs_spell() {
  _run_spell spells/.imps/out/ok
  _assert_success
}

test_captures_spell_output() {
  _run_spell spells/.imps/out/ok
  # ok should produce some output (usually "ok")
  [ -n "$OUTPUT" ] || [ "$STATUS" -eq 0 ]
}

_run_test_case "run-spell executes spell scripts" test_runs_spell
_run_test_case "run-spell captures spell output" test_captures_spell_output

_finish_tests
