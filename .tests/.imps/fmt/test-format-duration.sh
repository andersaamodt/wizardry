#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_format_seconds_only() {
  output=$("$test_root/spells/.imps/fmt/format-duration" 45)
  assert_equals "$output" "45s"
}

test_format_minutes_and_seconds() {
  output=$("$test_root/spells/.imps/fmt/format-duration" 125)
  assert_equals "$output" "2m 5s"
}

test_format_hours_minutes_seconds() {
  output=$("$test_root/spells/.imps/fmt/format-duration" 3665)
  assert_equals "$output" "1h 1m 5s"
}

test_format_days_hours_minutes_seconds() {
  output=$("$test_root/spells/.imps/fmt/format-duration" 90061)
  assert_equals "$output" "1d 1h 1m 1s"
}

test_format_exact_minute() {
  output=$("$test_root/spells/.imps/fmt/format-duration" 120)
  assert_equals "$output" "2m"
}

test_format_exact_hour() {
  output=$("$test_root/spells/.imps/fmt/format-duration" 7200)
  assert_equals "$output" "2h"
}

test_format_zero_seconds() {
  output=$("$test_root/spells/.imps/fmt/format-duration" 0)
  assert_equals "$output" "0s"
}

test_format_large_duration() {
  output=$("$test_root/spells/.imps/fmt/format-duration" 186543)
  assert_equals "$output" "2d 3h 49m 3s"
}

run_test_case "seconds only" test_format_seconds_only
run_test_case "minutes and seconds" test_format_minutes_and_seconds
run_test_case "hours minutes seconds" test_format_hours_minutes_seconds
run_test_case "days hours minutes seconds" test_format_days_hours_minutes_seconds
run_test_case "exact minute" test_format_exact_minute
run_test_case "exact hour" test_format_exact_hour
run_test_case "zero seconds" test_format_zero_seconds
run_test_case "large duration" test_format_large_duration
finish_tests
