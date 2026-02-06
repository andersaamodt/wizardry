#!/bin/sh
# Test chat-log-if-unique imp
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_first_message_logged() {
  testdir=$(mktemp -d)
  log_file="$testdir/test.log"
  
  chat-log-if-unique "$log_file" "[2026-01-30 06:00:00] log: Alice joined the room."
  
  result=$(cat "$log_file")
  rm -rf "$testdir"
  
  [ "$result" = "[2026-01-30 06:00:00] log: Alice joined the room." ]
}

test_duplicate_message_skipped() {
  testdir=$(mktemp -d)
  log_file="$testdir/test.log"
  
  chat-log-if-unique "$log_file" "[2026-01-30 06:00:00] log: Alice joined the room."
  chat-log-if-unique "$log_file" "[2026-01-30 06:00:01] log: Alice joined the room."
  
  line_count=$(wc -l < "$log_file")
  rm -rf "$testdir"
  
  [ "$line_count" -eq 1 ]
}

test_different_message_logged() {
  testdir=$(mktemp -d)
  log_file="$testdir/test.log"
  
  chat-log-if-unique "$log_file" "[2026-01-30 06:00:00] log: Alice joined the room."
  chat-log-if-unique "$log_file" "[2026-01-30 06:00:01] log: Alice left the room."
  
  line_count=$(wc -l < "$log_file")
  rm -rf "$testdir"
  
  [ "$line_count" -eq 2 ]
}

test_duplicate_after_other_message() {
  testdir=$(mktemp -d)
  log_file="$testdir/test.log"
  
  chat-log-if-unique "$log_file" "[2026-01-30 06:00:00] log: Alice joined the room."
  chat-log-if-unique "$log_file" "[2026-01-30 06:00:01] Alice: Hello"
  chat-log-if-unique "$log_file" "[2026-01-30 06:00:02] log: Alice joined the room."
  
  line_count=$(wc -l < "$log_file")
  last_line=$(tail -1 "$log_file")
  rm -rf "$testdir"
  
  [ "$line_count" -eq 3 ] && [ "$last_line" = "[2026-01-30 06:00:02] log: Alice joined the room." ]
}

test_blank_lines_ignored() {
  testdir=$(mktemp -d)
  log_file="$testdir/test.log"
  
  chat-log-if-unique "$log_file" "[2026-01-30 06:00:00] log: Alice joined the room."
  printf '\n\n' >> "$log_file"
  chat-log-if-unique "$log_file" "[2026-01-30 06:00:01] log: Alice joined the room."
  
  # Should have 1 message + 2 blank lines + no duplicate = 3 lines total
  line_count=$(wc -l < "$log_file")
  non_blank_count=$(grep -c -v '^[[:space:]]*$' "$log_file")
  rm -rf "$testdir"
  
  [ "$line_count" -eq 3 ] && [ "$non_blank_count" -eq 1 ]
}

run_test_case "first message is logged" test_first_message_logged
run_test_case "duplicate message is skipped" test_duplicate_message_skipped
run_test_case "different message is logged" test_different_message_logged
run_test_case "duplicate logged after different message" test_duplicate_after_other_message
run_test_case "blank lines are ignored when checking duplicates" test_blank_lines_ignored

finish_tests
