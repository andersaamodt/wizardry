#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_valid_room_names() {
  run_spell "spells/.imps/cgi/validate-room-name" "General"
  [ "$STATUS" -eq 0 ] || return 1
  
  run_spell "spells/.imps/cgi/validate-room-name" "MyRoom"
  [ "$STATUS" -eq 0 ] || return 1
  
  run_spell "spells/.imps/cgi/validate-room-name" "room-123"
  [ "$STATUS" -eq 0 ] || return 1
}

test_invalid_room_names() {
  # Path traversal
  run_spell "spells/.imps/cgi/validate-room-name" "../etc"
  [ "$STATUS" -ne 0 ] || return 1
  
  run_spell "spells/.imps/cgi/validate-room-name" "room/../admin"
  [ "$STATUS" -ne 0 ] || return 1
  
  # Slashes
  run_spell "spells/.imps/cgi/validate-room-name" "room/admin"
  [ "$STATUS" -ne 0 ] || return 1
  
  # Backslashes
  run_spell "spells/.imps/cgi/validate-room-name" "room\\admin"
  [ "$STATUS" -ne 0 ] || return 1
  
  # Empty
  run_spell "spells/.imps/cgi/validate-room-name" ""
  [ "$STATUS" -ne 0 ] || return 1
}

run_test_case "validates valid room names" test_valid_room_names
run_test_case "rejects invalid room names" test_invalid_room_names
finish_tests
