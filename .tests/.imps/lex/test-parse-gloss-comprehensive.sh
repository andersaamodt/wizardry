#!/bin/sh
# COMPREHENSIVE parse/gloss test suite
# Tests every combination of valid/invalid command invocations

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Helper to check no shift/parse errors
check_no_errors() {
  output="$1"
  if printf '%s' "$output" | grep -q "shift count"; then
    TEST_FAILURE_REASON="Shift error: $output"
    return 1
  fi
  if printf '%s' "$output" | grep -q "parse:.*command not found" | grep -qE "(jump-to.*jump-to-marker.*jump|leap-to.*leap-to-location.*leap)"; then
    TEST_FAILURE_REASON="Parse multi-arg error: $output"
    return 1
  fi
  return 0
}

### SECTION 1: Single-word commands ###

test_single_word_no_args() {
  OUTPUT=$(printf '' | jump 2>&1)
  check_no_errors "$OUTPUT"
}

test_single_word_with_numeric_arg() {
  OUTPUT=$(banish 5 2>&1 | head -5)
  check_no_errors "$OUTPUT" || return 1
  # Should call banish with arg 5, not look for banish-5
  if printf '%s' "$OUTPUT" | grep -q "banish-5"; then
    TEST_FAILURE_REASON="Looked for banish-5 instead of banish with arg 5"
    return 1
  fi
}

test_single_word_with_flag() {
  OUTPUT=$(jump --help 2>&1)
  check_no_errors "$OUTPUT"
}

test_single_word_with_text_arg() {
  OUTPUT=$(jump home 2>&1)
  check_no_errors "$OUTPUT"
}

### SECTION 2: Multi-word commands (hyphenated form) ###

test_multiword_hyphenated_no_args() {
  OUTPUT=$(jump-to-marker 2>&1)
  check_no_errors "$OUTPUT"
}

test_multiword_hyphenated_with_arg() {
  OUTPUT=$(jump-to-marker home 2>&1)
  check_no_errors "$OUTPUT"
}

test_multiword_hyphenated_with_flag() {
  OUTPUT=$(jump-to-marker --help 2>&1)
  check_no_errors "$OUTPUT"
}

test_multiword_hyphenated_with_numeric() {
  OUTPUT=$(jump-to-marker 1 2>&1)
  check_no_errors "$OUTPUT"
}

### SECTION 3: Multi-word commands (space-separated form) ###

test_multiword_spaces_no_args() {
  OUTPUT=$(jump to marker 2>&1)
  check_no_errors "$OUTPUT"
}

test_multiword_spaces_with_arg() {
  OUTPUT=$(jump to marker home 2>&1)
  check_no_errors "$OUTPUT"
}

test_multiword_spaces_with_flag() {
  OUTPUT=$(jump to marker --help 2>&1)
  check_no_errors "$OUTPUT"
}

test_multiword_spaces_with_numeric() {
  OUTPUT=$(jump to marker 1 2>&1)
  check_no_errors "$OUTPUT"
}

### SECTION 4: Three-word commands ###

test_threeword_hyphenated_if_exists() {
  # Check if mark-location-as exists (it might not)
  # This tests deeply nested multi-word commands
  if has mark-location-as 2>/dev/null; then
    OUTPUT=$(mark-location-as test 2>&1)
    check_no_errors "$OUTPUT"
  fi
}

### SECTION 5: Commands with numeric args (the banish 5 bug) ###

test_numeric_arg_level_0() {
  OUTPUT=$(banish 0 2>&1 | head -5)
  check_no_errors "$OUTPUT" || return 1
  printf '%s' "$OUTPUT" | grep -qE "(Level 0|Validating)" || return 1
}

test_numeric_arg_level_8() {
  OUTPUT=$(banish 8 2>&1 | head -5)
  check_no_errors "$OUTPUT" || return 1
  printf '%s' "$OUTPUT" | grep -qE "(Level 8|Validating)" || return 1
}

### SECTION 6: Commands with flags ###

test_multiword_flag_before_args() {
  OUTPUT=$(jump to marker --verbose home 2>&1)
  check_no_errors "$OUTPUT"
}

test_multiword_flags_only() {
  OUTPUT=$(jump to marker --help 2>&1)
  check_no_errors "$OUTPUT"
}

### SECTION 7: Invalid commands (should fail gracefully) ###

test_invalid_single_word() {
  OUTPUT=$(nonexistent-command-xyz 2>&1)
  STATUS=$?
  # Should fail but not with shift error
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="Should not have shift error for invalid command"
    return 1
  fi
}

test_invalid_multiword() {
  OUTPUT=$(nonexistent command sequence 2>&1)
  STATUS=$?
  # Should fail but not with shift error
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="Should not have shift error for invalid command"
    return 1
  fi
}

### SECTION 8: Edge cases ###

test_command_with_many_args() {
  OUTPUT=$(jump to marker arg1 arg2 arg3 arg4 2>&1)
  check_no_errors "$OUTPUT"
}

test_command_with_mixed_args() {
  OUTPUT=$(jump to marker --flag1 arg1 --flag2 arg2 2>&1)
  check_no_errors "$OUTPUT"
}

test_numeric_only_args() {
  OUTPUT=$(jump 1 2>&1)
  check_no_errors "$OUTPUT"
}

test_command_ending_in_number() {
  # "jump to 5" should be "jump to" with arg "5", not "jump-to-5"
  OUTPUT=$(jump to 5 2>&1)
  check_no_errors "$OUTPUT" || return 1
  # Should not look for "jump-to-5" command
  if printf '%s' "$OUTPUT" | grep -q "jump-to-5"; then
    TEST_FAILURE_REASON="Looked for jump-to-5 instead of 'jump to' with arg 5"
    return 1
  fi
}

### Run all tests ###

# Section 1
run_test_case "single word no args (jump)" test_single_word_no_args
run_test_case "single word numeric arg (banish 5)" test_single_word_with_numeric_arg
run_test_case "single word with flag (jump --help)" test_single_word_with_flag
run_test_case "single word with text arg (jump home)" test_single_word_with_text_arg

# Section 2
run_test_case "multiword hyphenated no args (jump-to-marker)" test_multiword_hyphenated_no_args
run_test_case "multiword hyphenated with arg (jump-to-marker home)" test_multiword_hyphenated_with_arg
run_test_case "multiword hyphenated with flag (jump-to-marker --help)" test_multiword_hyphenated_with_flag
run_test_case "multiword hyphenated with numeric (jump-to-marker 1)" test_multiword_hyphenated_with_numeric

# Section 3
run_test_case "multiword spaces no args (jump to marker)" test_multiword_spaces_no_args
run_test_case "multiword spaces with arg (jump to marker home)" test_multiword_spaces_with_arg
run_test_case "multiword spaces with flag (jump to marker --help)" test_multiword_spaces_with_flag
run_test_case "multiword spaces with numeric (jump to marker 1)" test_multiword_spaces_with_numeric

# Section 4
run_test_case "three-word command if exists" test_threeword_hyphenated_if_exists

# Section 5
run_test_case "numeric arg level 0 (banish 0)" test_numeric_arg_level_0
run_test_case "numeric arg level 8 (banish 8)" test_numeric_arg_level_8

# Section 6
run_test_case "multiword flag before args" test_multiword_flag_before_args
run_test_case "multiword flags only" test_multiword_flags_only

# Section 7
run_test_case "invalid single word (graceful fail)" test_invalid_single_word
run_test_case "invalid multiword (graceful fail)" test_invalid_multiword

# Section 8
run_test_case "command with many args" test_command_with_many_args
run_test_case "command with mixed args" test_command_with_mixed_args
run_test_case "numeric only args (jump 1)" test_numeric_only_args
run_test_case "command ending in number (jump to 5)" test_command_ending_in_number

finish_tests
