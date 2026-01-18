#!/bin/sh
# Tests for the 'pluralize' imp

# Locate the repository root so we can source test-bootstrap
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pluralize_singular() {
  skip-if-compiled || return $?
  run_spell spells/.imps/text/pluralize spell 1
  assert_success
  assert_output_contains "spell"
}

test_pluralize_default_plural() {
  skip-if-compiled || return $?
  run_spell spells/.imps/text/pluralize spell 2
  assert_success
  assert_output_contains "spells"
}

test_pluralize_irregular() {
  skip-if-compiled || return $?
  run_spell spells/.imps/text/pluralize child 2
  assert_success
  assert_output_contains "children"
}

test_pluralize_with_custom_plural() {
  skip-if-compiled || return $?
  run_spell spells/.imps/text/pluralize cactus 3 cactuses
  assert_success
  assert_output_contains "cactuses"
}

test_pluralize_preserves_capitalization() {
  skip-if-compiled || return $?
  # Enable debug mode for this test on macOS to see what's happening
  export PLURALIZE_DEBUG=1
  run_spell spells/.imps/text/pluralize Wizard 2
  unset PLURALIZE_DEBUG
  assert_success
  assert_output_contains "Wizards"
}

run_test_case "pluralize returns singular for count 1" test_pluralize_singular
run_test_case "pluralize applies default pluralization" test_pluralize_default_plural
run_test_case "pluralize handles irregulars" test_pluralize_irregular
run_test_case "pluralize uses custom plural" test_pluralize_with_custom_plural
run_test_case "pluralize preserves capitalization" test_pluralize_preserves_capitalization

finish_tests
