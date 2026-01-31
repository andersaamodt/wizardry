#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_generates_simple_div() {
  run_spell "spells/.imps/cgi/html-div" "test-class" "content"
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = '<div class="test-class">content</div>' ] || return 1
}

test_generates_div_with_html_content() {
  run_spell "spells/.imps/cgi/html-div" "demo-result" "<p>Hello</p>"
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = '<div class="demo-result"><p>Hello</p></div>' ] || return 1
}

test_handles_empty_content() {
  run_spell "spells/.imps/cgi/html-div" "empty" ""
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = '<div class="empty"></div>' ] || return 1
}

run_test_case "generates simple div" test_generates_simple_div
run_test_case "generates div with HTML content" test_generates_div_with_html_content
run_test_case "handles empty content" test_handles_empty_content
finish_tests
