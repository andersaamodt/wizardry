#!/bin/sh
# Test to reproduce the gloss bugs

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_jump_to_marker_spaces() {
  # This should work via gloss: "jump to marker" → jump-to-marker
  # Need to source invoke-wizardry in same shell context
  OUTPUT=$(jump to marker --help 2>&1)
  STATUS=$?
  
  if [ $STATUS -ne 0 ]; then
    TEST_FAILURE_REASON="Command failed with status $STATUS"
    return 1
  fi
  
  if ! printf '%s' "$OUTPUT" | grep -q "Usage:"; then
    TEST_FAILURE_REASON="Output missing 'Usage:'"
    return 1
  fi
}

test_warp_synonym() {
  # warp should be a synonym for jump-to-marker
  OUTPUT=$(warp --help 2>&1)
  STATUS=$?
  
  if [ $STATUS -ne 0 ]; then
    TEST_FAILURE_REASON="Command failed with status $STATUS; output: $OUTPUT"
    return 1
  fi
  
  if ! printf '%s' "$OUTPUT" | grep -q "Usage:"; then
    TEST_FAILURE_REASON="Output missing 'Usage:'"
    return 1
  fi
}

test_leap_to_location_synonym() {
  # leap-to-location should be a synonym for jump-to-marker  
  OUTPUT=$(leap-to-location --help 2>&1)
  STATUS=$?
  
  if [ $STATUS -ne 0 ]; then
    TEST_FAILURE_REASON="Command failed with status $STATUS; output: $OUTPUT"
    return 1
  fi
  
  if ! printf '%s' "$OUTPUT" | grep -q "Usage:"; then
    TEST_FAILURE_REASON="Output missing 'Usage:'"
    return 1
  fi
}

test_leap_to_location_spaces() {
  # "leap to location" should work via gloss
  OUTPUT=$(leap to location --help 2>&1)
  STATUS=$?
  
  if [ $STATUS -ne 0 ]; then
    TEST_FAILURE_REASON="Command failed with status $STATUS; output: $OUTPUT"
    return 1
  fi
  
  if ! printf '%s' "$OUTPUT" | grep -q "Usage:"; then
    TEST_FAILURE_REASON="Output missing 'Usage:'"
    return 1
  fi
}

run_test_case "jump to marker with spaces (gloss)" test_jump_to_marker_spaces
run_test_case "warp synonym" test_warp_synonym
run_test_case "leap-to-location synonym" test_leap_to_location_synonym
run_test_case "leap to location with spaces (gloss)" test_leap_to_location_spaces

finish_tests
