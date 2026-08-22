#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

extracts_string_from_stdin() {
  run_cmd sh -c "printf '%s' '{\"name\":\"wizardry\"}' | '$ROOT_DIR/spells/.imps/cgi/json-extract-string' name"
  assert_success || return 1
  [ "$OUTPUT" = wizardry ]
}

extracts_string_from_file() {
  fixture=$(make_tempdir)/value.json
  printf '%s\n' '{"name":"parity"}' > "$fixture"
  run_spell spells/.imps/cgi/json-extract-string name "$fixture"
  assert_success || return 1
  [ "$OUTPUT" = parity ]
}

requires_key() {
  run_spell spells/.imps/cgi/json-extract-string
  assert_failure
}

rejects_unsafe_key() {
  run_spell spells/.imps/cgi/json-extract-string 'bad/key'
  assert_failure
}

run_test_case "json-extract-string reads stdin" extracts_string_from_stdin
run_test_case "json-extract-string reads a file" extracts_string_from_file
run_test_case "json-extract-string requires a key" requires_key
run_test_case "json-extract-string rejects unsafe keys" rejects_unsafe_key
finish_tests
