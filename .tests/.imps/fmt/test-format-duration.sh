#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_format_seconds_only() {
  result=$(format_duration 45)
  _assert_equals "45s" "$result"
}

test_format_minutes_and_seconds() {
  result=$(format_duration 125)
  _assert_equals "2m 5s" "$result"
}

test_format_hours_minutes_seconds() {
  result=$(format_duration 3665)
  _assert_equals "1h 1m 5s" "$result"
}

test_format_days_hours_minutes_seconds() {
  result=$(format_duration 90061)
  _assert_equals "1d 1h 1m 1s" "$result"
}

test_format_exact_minute() {
  result=$(format_duration 120)
  _assert_equals "2m" "$result"
}

test_format_exact_hour() {
  result=$(format_duration 7200)
  _assert_equals "2h" "$result"
}

test_format_zero_seconds() {
  result=$(format_duration 0)
  _assert_equals "0s" "$result"
}

test_format_large_duration() {
  result=$(format_duration 186543)
  _assert_equals "2d 3h 49m 3s" "$result"
}

_run_test_case "seconds only" test_format_seconds_only
_run_test_case "minutes and seconds" test_format_minutes_and_seconds
_run_test_case "hours minutes seconds" test_format_hours_minutes_seconds
_run_test_case "days hours minutes seconds" test_format_days_hours_minutes_seconds
_run_test_case "exact minute" test_format_exact_minute
_run_test_case "exact hour" test_format_exact_hour
_run_test_case "zero seconds" test_format_zero_seconds
_run_test_case "large duration" test_format_large_duration
_finish_tests
