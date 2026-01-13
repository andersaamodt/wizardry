#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_initializes_counters() {
  # Run the imp in a subshell to test initialization without affecting our counters
  tmpdir=$(make_tempdir)
  export WIZARDRY_TMPDIR="$tmpdir"
  
  init-test-counters
  
  # Check that counter files exist and are initialized
  [ -f "$WIZARDRY_TMPDIR/_pass_count" ] || return 1
  [ -f "$WIZARDRY_TMPDIR/_fail_count" ] || return 1
  [ -f "$WIZARDRY_TMPDIR/_skip_count" ] || return 1
  [ -f "$WIZARDRY_TMPDIR/_test_index" ] || return 1
  [ -f "$WIZARDRY_TMPDIR/_fail_detail_indices" ] || return 1
}

test_counters_start_at_zero() {
  # Run the imp in a subshell to test values without affecting our counters
  tmpdir=$(make_tempdir)
  export WIZARDRY_TMPDIR="$tmpdir"
  
  init-test-counters
  
  # Verify counters start at zero
  [ "$(cat "$WIZARDRY_TMPDIR/_pass_count")" = "0" ] || return 1
  [ "$(cat "$WIZARDRY_TMPDIR/_fail_count")" = "0" ] || return 1
  [ "$(cat "$WIZARDRY_TMPDIR/_skip_count")" = "0" ] || return 1
  [ "$(cat "$WIZARDRY_TMPDIR/_test_index")" = "0" ] || return 1
}

run_test_case "initializes test counters" test_initializes_counters
run_test_case "counters start at zero" test_counters_start_at_zero
finish_tests
