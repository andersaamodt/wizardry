#!/bin/sh
# Tests for the 'append' imp

. "${0%/*}/../test-common.sh"

test_append_adds_to_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/append_test.XXXXXX")
  printf 'initial\n' > "$tmpfile"
  run_cmd sh -c "printf 'appended' | '$ROOT_DIR/spells/.imps/append' '$tmpfile'"
  content=$(cat "$tmpfile")
  rm -f "$tmpfile"
  assert_success
  case "$content" in
    *initial*appended*) return 0 ;;
    *) TEST_FAILURE_REASON="content should include both initial and appended"; return 1 ;;
  esac
}

run_test_case "append adds to file" test_append_adds_to_file

finish_tests
