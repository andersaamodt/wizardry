#!/bin/sh
# Test record-failure-detail imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Save original state
_orig_detail=$_fail_detail_indices

test_records_index() {
  _fail_detail_indices=""
  _record_failure_detail 1
  result=$_fail_detail_indices
  _fail_detail_indices=$_orig_detail
  [ "$result" = "1" ]
}

test_multiple_indices() {
  _fail_detail_indices=""
  _record_failure_detail 1
  _record_failure_detail 3
  result=$_fail_detail_indices
  _fail_detail_indices=$_orig_detail
  [ "$result" = "1,3" ]
}

_run_test_case "record-failure-detail records single index" test_records_index
_run_test_case "record-failure-detail records multiple indices" test_multiple_indices

_finish_tests
