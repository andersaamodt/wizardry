#!/bin/sh
# Behavioral cases for sigil:
# - emits safe key=value rows
# - rejects line-break forgery
# - rejects TSV delimiters
# - quotes JSON strings

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

sigil_emits_key_value() {
  run_spell "spells/.imps/pact/sigil" key-value status ok
  assert_success || return 1
  [ "$OUTPUT" = "status=ok" ] || {
    TEST_FAILURE_REASON="unexpected key-value output: $OUTPUT"
    return 1
  }
}

sigil_rejects_key_value_forgery() {
  forged='ok
status=bad'
  run_spell "spells/.imps/pact/sigil" key-value summary "$forged"
  assert_failure || return 1
}

sigil_rejects_tsv_delimiter() {
  tab=$(printf '\t')
  run_spell "spells/.imps/pact/sigil" tsv "left${tab}right"
  assert_failure || return 1
}

sigil_quotes_json_string() {
  run_spell "spells/.imps/pact/sigil" json-string 'a"b\c'
  assert_success || return 1
  [ "$OUTPUT" = '"a\"b\\c"' ] || {
    TEST_FAILURE_REASON="unexpected JSON string: $OUTPUT"
    return 1
  }
}

run_test_case "sigil emits key-value rows" sigil_emits_key_value
run_test_case "sigil rejects key-value forgery" sigil_rejects_key_value_forgery
run_test_case "sigil rejects TSV delimiters" sigil_rejects_tsv_delimiter
run_test_case "sigil quotes JSON strings" sigil_quotes_json_string

finish_tests
