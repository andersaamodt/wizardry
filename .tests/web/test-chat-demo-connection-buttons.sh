#!/bin/sh
# Tests for chat demo connection button disabling

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_chat_demo_disables_members_and_delete_buttons() {
  file="$ROOT_DIR/.templates/demo/pages/chat.md"

  if ! grep -q "deleteRoomBtn.disabled = isDisconnected" "$file"; then
    TEST_FAILURE_REASON="delete room button not disabled on disconnect"
    return 1
  fi

  if ! grep -q "membersBtn.disabled = isDisconnected" "$file"; then
    TEST_FAILURE_REASON="members button not disabled on disconnect"
    return 1
  fi
}

run_test_case "chat demo disables members/delete on disconnect" test_chat_demo_disables_members_and_delete_buttons

finish_tests
