#!/bin/sh
# Tests for the 'to' linking word imp

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_to_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/to" ]
}

test_to_appends_target() {
  tmp=$(make_tempdir)
  echo "content" > "$tmp/source.txt"
  
  run_spell spells/.imps/lex/to "cp" "$tmp/source.txt" "$tmp/dest.txt"
  assert_success || return 1
  
  if [ ! -f "$tmp/dest.txt" ]; then
    TEST_FAILURE_REASON="File not copied to destination"
    return 1
  fi
}

test_to_requires_target() {
  run_spell spells/.imps/lex/to "echo" "hello"
  assert_failure || return 1
}

test_to_requires_command() {
  run_spell spells/.imps/lex/to "" "" "/tmp/dest"
  assert_failure || return 1
}

run_test_case "to is executable" test_to_is_executable
run_test_case "to appends target to args" test_to_appends_target
run_test_case "to requires target" test_to_requires_target
run_test_case "to requires command" test_to_requires_command

finish_tests
