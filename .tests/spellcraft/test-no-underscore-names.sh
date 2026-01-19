#!/bin/sh
# Test that no spell or imp uses underscore-prefixed identifiers
# Underscore prefixes are an anti-pattern that violates our "no functions in spells/imps" rule

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_no_underscore_functions() {
  # Search for function definitions with underscore prefixes in spells
  underscore_funcs=$(find "$test_root/spells" -type f \
    ! -path "*/.*" \
    ! -path "*/test-*" \
    -exec grep -l "^[[:space:]]*_[a-zA-Z_][a-zA-Z0-9_]*() {" {} \; 2>/dev/null || true)
  
  if [ -n "$underscore_funcs" ]; then
    printf 'Found underscore-prefixed functions (anti-pattern):\n%s\n' "$underscore_funcs" >&2
    return 1
  fi
  
  return 0
}

test_no_underscore_variables_in_loops() {
  # Search for underscore-prefixed loop variables
  underscore_vars=$(find "$test_root/spells" -type f \
    ! -path "*/.*" \
    ! -path "*/test-*" \
    -exec grep -l "for _[a-zA-Z_][a-zA-Z0-9_]* in" {} \; 2>/dev/null || true)
  
  if [ -n "$underscore_vars" ]; then
    printf 'Found underscore-prefixed loop variables (anti-pattern):\n%s\n' "$underscore_vars" >&2
    return 1
  fi
  
  return 0
}

run_test_case "No underscore-prefixed functions in spells" test_no_underscore_functions
run_test_case "No underscore-prefixed variables in spells" test_no_underscore_variables_in_loops
finish_tests
