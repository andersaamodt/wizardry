#!/bin/sh
# Tests for the 'term' imp

. "${0%/*}/../test_common.sh"

test_term_detects() {
  # This is tricky to test since we may or may not be in a terminal
  run_spell spells/.imps/term
  # Just verify it exits without error
  [ "$STATUS" -eq 0 ] || [ "$STATUS" -eq 1 ]
}

run_test_case "term detects terminal" test_term_detects

finish_tests
