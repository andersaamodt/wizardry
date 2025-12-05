#!/bin/sh
# Tests for the 'append' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_append_adds_to_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/append_test.XXXXXX")
  printf 'initial\n' > "$tmpfile"
  run_cmd sh -c "printf 'appended' | '$ROOT_DIR/spells/.imps/text/append' '$tmpfile'"
  content=$(cat "$tmpfile")
  rm -f "$tmpfile"
  assert_success
  case "$content" in
    *initial*appended*) return 0 ;;
    *) TEST_FAILURE_REASON="content should include both initial and appended"; return 1 ;;
  esac
}

test_append_creates_file_if_not_exists() {
  tmpfile="$WIZARDRY_TMPDIR/append_new_$$"
  run_cmd sh -c "printf 'new content' | '$ROOT_DIR/spells/.imps/text/append' '$tmpfile'"
  assert_success
  content=$(cat "$tmpfile" 2>/dev/null)
  rm -f "$tmpfile"
  [ "$content" = "new content" ] || { TEST_FAILURE_REASON="file should be created"; return 1; }
}

run_test_case "append adds to file" test_append_adds_to_file
run_test_case "append creates file if not exists" test_append_creates_file_if_not_exists

finish_tests
