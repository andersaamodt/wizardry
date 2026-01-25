#!/bin/sh
# Test coverage for validate-player-name imp:
# - Accepts valid player names
# - Rejects names that are too short
# - Rejects names that are too long
# - Rejects names starting with non-letter
# - Rejects names with invalid characters
# - Rejects empty names

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_accepts_valid_name() {
  run_spell "spells/.imps/input/validate-player-name" "Gandalf"
  assert_success || return 1
}

test_accepts_with_numbers() {
  run_spell "spells/.imps/input/validate-player-name" "Player123"
  assert_success || return 1
}

test_accepts_with_underscores() {
  run_spell "spells/.imps/input/validate-player-name" "dark_wizard"
  assert_success || return 1
}

test_rejects_too_short() {
  run_spell "spells/.imps/input/validate-player-name" "ab"
  assert_failure || return 1
  assert_error_contains "at least 3 characters" || return 1
}

test_rejects_too_long() {
  run_spell "spells/.imps/input/validate-player-name" "verylongplayername123"
  assert_failure || return 1
  assert_error_contains "16 characters or less" || return 1
}

test_rejects_starts_with_number() {
  run_spell "spells/.imps/input/validate-player-name" "1player"
  assert_failure || return 1
  assert_error_contains "must start with a letter" || return 1
}

test_rejects_starts_with_underscore() {
  run_spell "spells/.imps/input/validate-player-name" "_player"
  assert_failure || return 1
  assert_error_contains "must start with a letter" || return 1
}

test_rejects_with_dash() {
  run_spell "spells/.imps/input/validate-player-name" "player-name"
  assert_failure || return 1
  assert_error_contains "letters, digits, and underscores" || return 1
}

test_rejects_with_space() {
  run_spell "spells/.imps/input/validate-player-name" "player name"
  assert_failure || return 1
  assert_error_contains "letters, digits, and underscores" || return 1
}

test_rejects_with_dot() {
  run_spell "spells/.imps/input/validate-player-name" "player.name"
  assert_failure || return 1
  assert_error_contains "letters, digits, and underscores" || return 1
}

test_rejects_empty() {
  run_spell "spells/.imps/input/validate-player-name" ""
  assert_failure || return 1
  assert_error_contains "cannot be empty" || return 1
}

run_test_case "validate-player-name accepts valid names" test_accepts_valid_name
run_test_case "validate-player-name accepts with numbers" test_accepts_with_numbers
run_test_case "validate-player-name accepts with underscores" test_accepts_with_underscores
run_test_case "validate-player-name rejects too short" test_rejects_too_short
run_test_case "validate-player-name rejects too long" test_rejects_too_long
run_test_case "validate-player-name rejects starts with number" test_rejects_starts_with_number
run_test_case "validate-player-name rejects starts with underscore" test_rejects_starts_with_underscore
run_test_case "validate-player-name rejects with dash" test_rejects_with_dash
run_test_case "validate-player-name rejects with space" test_rejects_with_space
run_test_case "validate-player-name rejects with dot" test_rejects_with_dot
run_test_case "validate-player-name rejects empty" test_rejects_empty

finish_tests
