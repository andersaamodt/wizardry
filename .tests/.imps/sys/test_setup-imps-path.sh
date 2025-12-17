#!/bin/sh
# Tests for the 'setup-imps-path' imp

# Locate the repository root
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_setup_imps_path_works() {
  # Test that sourcing setup-imps-path modifies PATH
  # This is a basic smoke test - just verify it can be sourced without error
  # and that it adds something to PATH
  
  # Run in subshell to avoid polluting current PATH
  (
    cd "$test_root/spells/arcane" || exit 1
    original_len=$(printf '%s' "$PATH" | wc -c)
    . ../.imps/sys/setup-imps-path || exit 1
    new_len=$(printf '%s' "$PATH" | wc -c)
    # PATH should be longer after sourcing setup-imps-path
    [ "$new_len" -gt "$original_len" ] || exit 1
  )
}

_run_test_case "setup-imps-path modifies PATH correctly" test_setup_imps_path_works

_finish_tests

