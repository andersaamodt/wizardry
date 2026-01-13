#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_format_seconds_only() {
  result=$(format_duration 45)
  assert-equals "45s" "$result"
}

test_format_minutes_and_seconds() {
  result=$(format_duration 125)
  assert-equals "2m 5s" "$result"
}

test_format_hours_minutes_seconds() {
  result=$(format_duration 3665)
  assert-equals "1h 1m 5s" "$result"
}

test_format_days_hours_minutes_seconds() {
  result=$(format_duration 90061)
  assert-equals "1d 1h 1m 1s" "$result"
}

test_format_exact_minute() {
  result=$(format_duration 120)
  assert-equals "2m" "$result"
}

test_format_exact_hour() {
  result=$(format_duration 7200)
  assert-equals "2h" "$result"
}

test_format_zero_seconds() {
  result=$(format_duration 0)
  assert-equals "0s" "$result"
}

test_format_large_duration() {
  result=$(format_duration 186543)
  assert-equals "2d 3h 49m 3s" "$result"
}

run-test-case "seconds only" test_format_seconds_only
run-test-case "minutes and seconds" test_format_minutes_and_seconds
run-test-case "hours minutes seconds" test_format_hours_minutes_seconds
run-test-case "days hours minutes seconds" test_format_days_hours_minutes_seconds
run-test-case "exact minute" test_format_exact_minute
run-test-case "exact hour" test_format_exact_hour
run-test-case "zero seconds" test_format_zero_seconds
run-test-case "large duration" test_format_large_duration
finish-tests
