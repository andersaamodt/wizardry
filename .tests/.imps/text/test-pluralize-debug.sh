#!/bin/sh
# Standalone debug test for pluralize - shows all methods on all platforms
# Run this directly to see debug output: .tests/.imps/text/test-pluralize-debug.sh

set -eu

# Find the repository root
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -d "$test_root/spells" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done

printf '=== Pluralize Debug Test ===\n'
printf 'Platform: %s\n' "$(uname -s)"
printf 'Shell: %s\n\n' "${SHELL:-sh}"

# Enable debug mode
export PLURALIZE_DEBUG=1

# Test the capitalization case
printf '%s\n' '--- Test: Wizard -> Wizards ---'
result=$("$test_root/spells/.imps/text/pluralize" Wizard 2 2>&1)
printf '\nFull output:\n%s\n\n' "$result"

# Check if it contains "Wizards"
case "$result" in
  *Wizards*)
    printf '✓ SUCCESS: Output contains "Wizards"\n'
    exit 0
    ;;
  *)
    printf '✗ FAILURE: Output does NOT contain "Wizards"\n'
    printf 'This is the actual output that will help debug the macOS issue.\n'
    exit 1
    ;;
esac
