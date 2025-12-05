#!/bin/sh
# Tests for the 'to' linking word imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_to_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/to" ]
}

test_to_appends_target() {
  tmp=$(_make_tempdir)
  echo "content" > "$tmp/source.txt"
  
  _run_spell spells/.imps/lex/to "cp" "$tmp/source.txt" "$tmp/dest.txt"
  _assert_success || return 1
  
  if [ ! -f "$tmp/dest.txt" ]; then
    TEST_FAILURE_REASON="File not copied to destination"
    return 1
  fi
}

test_to_requires_target() {
  _run_spell spells/.imps/lex/to "echo" "hello"
  _assert_failure || return 1
}

test_to_requires_command() {
  _run_spell spells/.imps/lex/to "" "" "/tmp/dest"
  _assert_failure || return 1
}

_run_test_case "to is executable" test_to_is_executable
_run_test_case "to appends target to args" test_to_appends_target
_run_test_case "to requires target" test_to_requires_target
_run_test_case "to requires command" test_to_requires_command

_finish_tests
