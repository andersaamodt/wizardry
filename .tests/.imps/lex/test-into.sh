#!/bin/sh
# Tests for the 'into' linking word imp

. "${0%/*}/../../test-common.sh"

test_into_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/into" ]
}

test_into_appends_target() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/target"
  echo "content" > "$tmp/source.txt"
  
  run_spell spells/.imps/lex/into "cp" "$tmp/source.txt" "$tmp/target"
  assert_success || return 1
  
  if [ ! -f "$tmp/target/source.txt" ]; then
    TEST_FAILURE_REASON="File not copied to target directory"
    return 1
  fi
}

test_into_requires_target() {
  run_spell spells/.imps/lex/into "echo" "hello"
  assert_failure || return 1
}

test_into_requires_command() {
  run_spell spells/.imps/lex/into "" "" "/tmp"
  assert_failure || return 1
}

run_test_case "into is executable" test_into_is_executable
run_test_case "into appends target to args" test_into_appends_target
run_test_case "into requires target" test_into_requires_target
run_test_case "into requires command" test_into_requires_command

finish_tests
