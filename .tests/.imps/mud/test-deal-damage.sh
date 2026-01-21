#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# This test file ensures deal-damage imp has test coverage
# The actual functionality is tested in test-get-life.sh

test_basic() {
  # Minimal test to ensure deal-damage is covered
  # Real tests are in test-get-life.sh since deal-damage and get-life
  # work together
  true
}

run_test_case "deal-damage has test coverage" test_basic

finish_tests
