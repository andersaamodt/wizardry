#!/bin/sh
# Tests for new self-documenting imps: is-integer, in-range, equals, differs, count-chars

. "${0%/*}/../test_common.sh"

# is-integer tests - all valid integer formats
test_is_integer_positive() {
  run_spell spells/.imps/is-integer "42"
  assert_success
}

test_is_integer_negative() {
  run_spell spells/.imps/is-integer "-5"
  assert_success
}

test_is_integer_zero() {
  run_spell spells/.imps/is-integer "0"
  assert_success
}

test_is_integer_large_negative() {
  run_spell spells/.imps/is-integer "-12345"
  assert_success
}

test_is_integer_large_positive() {
  run_spell spells/.imps/is-integer "99999"
  assert_success
}

# is-integer tests - rejection cases
test_is_integer_rejects_empty() {
  run_spell spells/.imps/is-integer ""
  assert_failure
}

test_is_integer_rejects_letters() {
  run_spell spells/.imps/is-integer "abc"
  assert_failure
}

test_is_integer_rejects_mixed() {
  run_spell spells/.imps/is-integer "12abc"
  assert_failure
}

test_is_integer_rejects_embedded_dash() {
  run_spell spells/.imps/is-integer "12-34"
  assert_failure
}

test_is_integer_rejects_only_dash() {
  run_spell spells/.imps/is-integer "-"
  assert_failure
}

test_is_integer_rejects_float() {
  run_spell spells/.imps/is-integer "3.14"
  assert_failure
}

test_is_integer_rejects_spaces() {
  run_spell spells/.imps/is-integer "1 2"
  assert_failure
}

# in-range tests - success cases
test_in_range_middle() {
  run_spell spells/.imps/in-range 5 1 10
  assert_success
}

test_in_range_at_min() {
  run_spell spells/.imps/in-range 1 1 10
  assert_success
}

test_in_range_at_max() {
  run_spell spells/.imps/in-range 10 1 10
  assert_success
}

test_in_range_single_value() {
  run_spell spells/.imps/in-range 5 5 5
  assert_success
}

test_in_range_negative_range() {
  run_spell spells/.imps/in-range -5 -10 -1
  assert_success
}

# in-range tests - rejection cases
test_in_range_below_min() {
  run_spell spells/.imps/in-range 0 1 10
  assert_failure
}

test_in_range_above_max() {
  run_spell spells/.imps/in-range 11 1 10
  assert_failure
}

test_in_range_far_below() {
  run_spell spells/.imps/in-range -100 1 10
  assert_failure
}

test_in_range_wrong_arg_count() {
  run_spell spells/.imps/in-range 5 1
  assert_failure
}

test_in_range_too_many_args() {
  run_spell spells/.imps/in-range 5 1 10 20
  assert_failure
}

# equals tests - success cases
test_equals_same_string() {
  run_spell spells/.imps/equals "hello" "hello"
  assert_success
}

test_equals_same_number() {
  run_spell spells/.imps/equals "42" "42"
  assert_success
}

test_equals_empty_strings() {
  run_spell spells/.imps/equals "" ""
  assert_success
}

test_equals_with_spaces() {
  run_spell spells/.imps/equals "hello world" "hello world"
  assert_success
}

# equals tests - rejection cases
test_equals_different_strings() {
  run_spell spells/.imps/equals "hello" "world"
  assert_failure
}

test_equals_case_sensitive() {
  run_spell spells/.imps/equals "Hello" "hello"
  assert_failure
}

test_equals_one_empty() {
  run_spell spells/.imps/equals "hello" ""
  assert_failure
}

test_equals_substring() {
  run_spell spells/.imps/equals "hello" "hel"
  assert_failure
}

# differs tests - success cases
test_differs_different_strings() {
  run_spell spells/.imps/differs "hello" "world"
  assert_success
}

test_differs_case_different() {
  run_spell spells/.imps/differs "Hello" "hello"
  assert_success
}

test_differs_one_empty() {
  run_spell spells/.imps/differs "hello" ""
  assert_success
}

test_differs_substring() {
  run_spell spells/.imps/differs "hello" "hel"
  assert_success
}

# differs tests - rejection cases
test_differs_same_string() {
  run_spell spells/.imps/differs "hello" "hello"
  assert_failure
}

test_differs_both_empty() {
  run_spell spells/.imps/differs "" ""
  assert_failure
}

test_differs_same_number() {
  run_spell spells/.imps/differs "42" "42"
  assert_failure
}

# count-chars tests with arguments
test_count_chars_simple() {
  run_spell spells/.imps/count-chars "hello"
  assert_success
  assert_output_contains "5"
}

test_count_chars_empty() {
  run_spell spells/.imps/count-chars ""
  assert_success
  assert_output_contains "0"
}

test_count_chars_with_spaces() {
  run_spell spells/.imps/count-chars "a b c"
  assert_success
  assert_output_contains "5"
}

test_count_chars_unicode() {
  # Note: count-chars uses wc -c which counts bytes, not Unicode characters
  run_spell spells/.imps/count-chars "test"
  assert_success
  assert_output_contains "4"
}

# count-chars tests with stdin
test_count_chars_stdin() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/count_test.XXXXXX")
  printf 'hello' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | $ROOT_DIR/spells/.imps/count-chars"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "5"
}

test_count_chars_stdin_with_newline() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/count_test.XXXXXX")
  printf 'test\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | $ROOT_DIR/spells/.imps/count-chars"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "5"
}

# Run all tests
run_test_case "is-integer accepts positive" test_is_integer_positive
run_test_case "is-integer accepts negative" test_is_integer_negative
run_test_case "is-integer accepts zero" test_is_integer_zero
run_test_case "is-integer accepts large negative" test_is_integer_large_negative
run_test_case "is-integer accepts large positive" test_is_integer_large_positive
run_test_case "is-integer rejects empty" test_is_integer_rejects_empty
run_test_case "is-integer rejects letters" test_is_integer_rejects_letters
run_test_case "is-integer rejects mixed" test_is_integer_rejects_mixed
run_test_case "is-integer rejects embedded dash" test_is_integer_rejects_embedded_dash
run_test_case "is-integer rejects only dash" test_is_integer_rejects_only_dash
run_test_case "is-integer rejects float" test_is_integer_rejects_float
run_test_case "is-integer rejects spaces" test_is_integer_rejects_spaces
run_test_case "in-range accepts middle" test_in_range_middle
run_test_case "in-range accepts at min" test_in_range_at_min
run_test_case "in-range accepts at max" test_in_range_at_max
run_test_case "in-range accepts single value range" test_in_range_single_value
run_test_case "in-range accepts negative range" test_in_range_negative_range
run_test_case "in-range rejects below min" test_in_range_below_min
run_test_case "in-range rejects above max" test_in_range_above_max
run_test_case "in-range rejects far below" test_in_range_far_below
run_test_case "in-range rejects wrong arg count" test_in_range_wrong_arg_count
run_test_case "in-range rejects too many args" test_in_range_too_many_args
run_test_case "equals accepts same string" test_equals_same_string
run_test_case "equals accepts same number" test_equals_same_number
run_test_case "equals accepts empty strings" test_equals_empty_strings
run_test_case "equals accepts with spaces" test_equals_with_spaces
run_test_case "equals rejects different strings" test_equals_different_strings
run_test_case "equals is case sensitive" test_equals_case_sensitive
run_test_case "equals rejects one empty" test_equals_one_empty
run_test_case "equals rejects substring" test_equals_substring
run_test_case "differs accepts different strings" test_differs_different_strings
run_test_case "differs accepts case difference" test_differs_case_different
run_test_case "differs accepts one empty" test_differs_one_empty
run_test_case "differs accepts substring" test_differs_substring
run_test_case "differs rejects same string" test_differs_same_string
run_test_case "differs rejects both empty" test_differs_both_empty
run_test_case "differs rejects same number" test_differs_same_number
run_test_case "count-chars counts simple string" test_count_chars_simple
run_test_case "count-chars handles empty" test_count_chars_empty
run_test_case "count-chars counts with spaces" test_count_chars_with_spaces
run_test_case "count-chars counts bytes" test_count_chars_unicode
run_test_case "count-chars reads stdin" test_count_chars_stdin
run_test_case "count-chars stdin with newline" test_count_chars_stdin_with_newline

finish_tests
