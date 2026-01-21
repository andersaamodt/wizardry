#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_strips_ansi_colors() {
  # Create ANSI colored text
  esc=$(printf '\033')
  input="${esc}[31mred${esc}[0m text"
  output=$(printf '%s' "$input" | "$ROOT_DIR/spells/.imps/test/socat-normalize-output")
  
  # Output should have ANSI codes removed
  case "$output" in
    *"${esc}"*)
      TEST_FAILURE_REASON="expected no ANSI escapes in output, got: $output"
      return 1
      ;;
    *"red text"*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="expected 'red text' in output, got: $output"
      return 1
      ;;
  esac
}

test_strips_carriage_returns() {
  # Create text with carriage returns
  input="line1\r\nline2\r\n"
  output=$(printf '%s' "$input" | "$ROOT_DIR/spells/.imps/test/socat-normalize-output")
  
  # Output should have \r removed but keep \n
  # Use portable approach to check for CR
  cr=$(printf '\r')
  case "$output" in
    *"$cr"*)
      TEST_FAILURE_REASON="expected no carriage returns in output, got: $(printf '%s' "$output" | od -An -tx1)"
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

run_test_case "socat-normalize-output strips ANSI colors" test_strips_ansi_colors
run_test_case "socat-normalize-output strips carriage returns" test_strips_carriage_returns
finish_tests
