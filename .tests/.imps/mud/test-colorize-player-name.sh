#!/bin/sh
# Test coverage for colorize-player-name imp

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_returns_color_code() {
  run_spell "spells/.imps/mud/colorize-player-name" "Alice"
  assert_success || return 1
  
  # Should output a number between 31-36
  case "$OUTPUT" in
    31|32|33|34|35|36) : ;;
    *) return 1 ;;
  esac
}

test_consistent_colors() {
  run_spell "spells/.imps/mud/colorize-player-name" "Alice"
  color1=$OUTPUT
  
  run_spell "spells/.imps/mud/colorize-player-name" "Alice"
  color2=$OUTPUT
  
  # Same name should always get same color
  [ "$color1" = "$color2" ] || return 1
}

test_different_names_can_differ() {
  run_spell "spells/.imps/mud/colorize-player-name" "Alice"
  color_alice=$OUTPUT
  
  run_spell "spells/.imps/mud/colorize-player-name" "Bob"
  color_bob=$OUTPUT
  
  # Different names might get different colors (not guaranteed, but likely)
  # This test just checks both are valid
  case "$color_alice" in
    31|32|33|34|35|36) : ;;
    *) return 1 ;;
  esac
  
  case "$color_bob" in
    31|32|33|34|35|36) : ;;
    *) return 1 ;;
  esac
}

test_requires_name() {
  run_spell "spells/.imps/mud/colorize-player-name"
  assert_failure || return 1
  assert_error_contains "requires player name" || return 1
}

run_test_case "colorize-player-name returns valid color code" test_returns_color_code
run_test_case "colorize-player-name is consistent" test_consistent_colors
run_test_case "colorize-player-name works for different names" test_different_names_can_differ
run_test_case "colorize-player-name requires name argument" test_requires_name

finish_tests
