#!/bin/sh
# Tests for stub-await-keypress-sequence

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_stub_returns_sequence() {
  tmpdir=$(make_tempdir)
  export AWAIT_KEYPRESS_SEQUENCE="up down enter"
  export AWAIT_KEYPRESS_INDEX_FILE="$tmpdir/index"
  
  # First call should return "up"
  run_spell "spells/.imps/test/stub-await-keypress-sequence"
  assert_success || return 1
  assert_output_contains "up" || return 1
  
  # Second call should return "down"
  run_spell "spells/.imps/test/stub-await-keypress-sequence"
  assert_success || return 1
  assert_output_contains "down" || return 1
  
  # Third call should return "enter"
  run_spell "spells/.imps/test/stub-await-keypress-sequence"
  assert_success || return 1
  assert_output_contains "enter" || return 1
  
  cleanup-dir "$tmpdir"
}

test_stub_wraps_around() {
  tmpdir=$(make_tempdir)
  export AWAIT_KEYPRESS_SEQUENCE="a b"
  export AWAIT_KEYPRESS_INDEX_FILE="$tmpdir/index"
  
  # Call three times - should wrap to "a" on third call
  run_spell "spells/.imps/test/stub-await-keypress-sequence" >/dev/null
  run_spell "spells/.imps/test/stub-await-keypress-sequence" >/dev/null
  run_spell "spells/.imps/test/stub-await-keypress-sequence"
  assert_success || return 1
  assert_output_contains "a" || return 1
  
  cleanup-dir "$tmpdir"
}

test_stub_defaults_to_enter() {
  tmpdir=$(make_tempdir)
  unset AWAIT_KEYPRESS_SEQUENCE
  export AWAIT_KEYPRESS_INDEX_FILE="$tmpdir/index"
  
  run_spell "spells/.imps/test/stub-await-keypress-sequence"
  assert_success || return 1
  assert_output_contains "enter" || return 1
  
  cleanup-dir "$tmpdir"
}

run_test_case "returns keys in sequence" test_stub_returns_sequence
run_test_case "wraps around when sequence exhausted" test_stub_wraps_around
run_test_case "defaults to enter when no sequence set" test_stub_defaults_to_enter

finish_tests
