#!/bin/sh
# Tests for the 'from' linking word imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_from_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/from" ]
}

test_from_prepends_source() {
  tmp=$(_make_tempdir)
  echo "content" > "$tmp/source.txt"
  
  _run_spell spells/.imps/lex/from "cp" "$tmp/dest.txt" "$tmp/source.txt"
  _assert_success || return 1
  
  if [ ! -f "$tmp/dest.txt" ]; then
    TEST_FAILURE_REASON="File not copied from source"
    return 1
  fi
}

test_from_requires_source() {
  _run_spell spells/.imps/lex/from "echo" "hello"
  _assert_failure || return 1
}

test_from_requires_command() {
  _run_spell spells/.imps/lex/from "" "" "/tmp/source"
  _assert_failure || return 1
}

_run_test_case "from is executable" test_from_is_executable
_run_test_case "from prepends source to args" test_from_prepends_source
_run_test_case "from requires source" test_from_requires_source
_run_test_case "from requires command" test_from_requires_command

_finish_tests
