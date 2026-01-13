#!/bin/sh
# Test record-failure-detail imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_records_index() {
  # Initialize the file
  printf '' > "$WIZARDRY_TMPDIR/_fail_detail_indices"
  
  record-failure-detail 1
  result=$(cat "$WIZARDRY_TMPDIR/_fail_detail_indices")
  [ "$result" = "1" ]
}

test_multiple_indices() {
  # Initialize the file
  printf '' > "$WIZARDRY_TMPDIR/_fail_detail_indices"
  
  record-failure-detail 1
  record-failure-detail 3
  result=$(cat "$WIZARDRY_TMPDIR/_fail_detail_indices")
  [ "$result" = "1,3" ]
}

run_test_case "record-failure-detail records single index" test_records_index
run_test_case "record-failure-detail records multiple indices" test_multiple_indices

finish_tests
