#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_extracts_first_param() {
  run_spell "spells/.imps/cgi/get-query-param" "text" "text=hello"
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = "hello" ] || return 1
}

test_extracts_from_multiple_params() {
  run_spell "spells/.imps/cgi/get-query-param" "name" "text=hello&name=world&age=42"
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = "world" ] || return 1
}

test_decodes_url_encoding() {
  run_spell "spells/.imps/cgi/get-query-param" "text" "text=hello%20world"
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = "hello world" ] || return 1
}

test_returns_empty_for_missing_param() {
  run_spell "spells/.imps/cgi/get-query-param" "missing" "text=hello"
  [ "$STATUS" -eq 0 ] || return 1
  [ -z "$OUTPUT" ] || return 1
}

test_uses_env_query_string_if_not_provided() {
  QUERY_STRING="foo=bar" run_spell "spells/.imps/cgi/get-query-param" "foo"
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = "bar" ] || return 1
}

run_test_case "extracts first parameter" test_extracts_first_param
run_test_case "extracts from multiple parameters" test_extracts_from_multiple_params
run_test_case "decodes URL encoding" test_decodes_url_encoding
run_test_case "returns empty for missing parameter" test_returns_empty_for_missing_param
run_test_case "uses QUERY_STRING env var if not provided" test_uses_env_query_string_if_not_provided
finish_tests
