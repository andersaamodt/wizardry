#!/bin/sh
# Tests for the 'count-words' imp

# Locate the repository root so we can source test-bootstrap
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_count_words_simple() {
  skip-if-compiled || return $?
  run_spell spells/.imps/text/count-words "hello wizardry world"
  assert_success
  assert_output_contains "3"
}

test_count_words_trims_whitespace() {
  skip-if-compiled || return $?
  run_cmd sh -c 'printf "  one\t\n two   three  " | "$1"' sh "$ROOT_DIR/spells/.imps/text/count-words"
  assert_success
  assert_output_contains "3"
}

run_test_case "count-words counts simple strings" test_count_words_simple
run_test_case "count-words trims whitespace" test_count_words_trims_whitespace

finish_tests
