#!/bin/sh
# Tests for the 'into' linking word imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_into_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/into" ]
}

test_into_appends_target() {
  tmp=$(_make_tempdir)
  mkdir -p "$tmp/target"
  echo "content" > "$tmp/source.txt"
  
  _run_spell spells/.imps/lex/into "cp" "$tmp/source.txt" "$tmp/target"
  _assert_success || return 1
  
  if [ ! -f "$tmp/target/source.txt" ]; then
    TEST_FAILURE_REASON="File not copied to target directory"
    return 1
  fi
}

test_into_requires_target() {
  _run_spell spells/.imps/lex/into "echo" "hello"
  _assert_failure || return 1
}

test_into_requires_command() {
  _run_spell spells/.imps/lex/into "" "" "/tmp"
  _assert_failure || return 1
}

_run_test_case "into is executable" test_into_is_executable
_run_test_case "into appends target to args" test_into_appends_target
_run_test_case "into requires target" test_into_requires_target
_run_test_case "into requires command" test_into_requires_command

_finish_tests
