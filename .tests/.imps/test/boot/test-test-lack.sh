#!/bin/sh
# Test test-lack imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_outputs_lack_message() {
  output=$(_test_lack "test-spell" "missing --help test")
  echo "$output" | grep -q "^LACK test-spell (missing --help test)$"
}

test_handles_multiple_reasons() {
  output=$(_test_lack "test-spell" "2 subtests; missing --help test")
  echo "$output" | grep -q "^LACK test-spell (2 subtests; missing --help test)$"
}

test_handles_special_chars() {
  output=$(_test_lack "test-spell" "reason's text")
  echo "$output" | grep -q "LACK test-spell (reason's text)"
}

_run_test_case "test-lack outputs LACK message" test_outputs_lack_message
_run_test_case "test-lack handles multiple reasons" test_handles_multiple_reasons
_run_test_case "test-lack handles special characters" test_handles_special_chars

_finish_tests
