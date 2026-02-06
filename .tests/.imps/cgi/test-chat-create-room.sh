#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_chat_create_room_exists() {
  [ -x "spells/.imps/cgi/chat-create-room" ]
}

test_chat_create_room_log_permissions() {
  # Set up test environment
  test_site_dir=$(temp-dir chat-test-site)
  export WIZARDRY_SITE_NAME="testsite"
  export WIZARDRY_SITES_DIR="$test_site_dir"
  
  # Create CGI request for creating a room
  export REQUEST_METHOD="GET"
  export QUERY_STRING="name=testroom"
  
  # Run chat-create-room
  run_spell spells/.imps/cgi/chat-create-room > /dev/null 2>&1
  
  # Check that .log file was created with correct permissions
  log_file="$test_site_dir/.sitedata/testsite/chatrooms/testroom/.log"
  
  if [ ! -f "$log_file" ]; then
    TEST_FAILURE_REASON=".log file not created"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  # Check permissions (should be 664)
  perms=$(stat -c '%a' "$log_file" 2>/dev/null || \
          stat -f '%Lp' "$log_file" 2>/dev/null || echo "000")
  
  if [ "$perms" != "664" ]; then
    TEST_FAILURE_REASON=".log file has permissions $perms, expected 664"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  rm -rf "$test_site_dir"
}

run_test_case "chat-create-room is executable" test_chat_create_room_exists
run_test_case "chat-create-room creates log with correct permissions" test_chat_create_room_log_permissions
finish_tests
