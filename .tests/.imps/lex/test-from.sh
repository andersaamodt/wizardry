#!/bin/sh
# Tests for the 'from' linking word imp

. "${0%/*}/../../test-common.sh"

test_from_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/from" ]
}

test_from_prepends_source() {
  tmp=$(make_tempdir)
  echo "content" > "$tmp/source.txt"
  
  run_spell spells/.imps/lex/from "cp" "$tmp/dest.txt" "$tmp/source.txt"
  assert_success || return 1
  
  if [ ! -f "$tmp/dest.txt" ]; then
    TEST_FAILURE_REASON="File not copied from source"
    return 1
  fi
}

test_from_requires_source() {
  run_spell spells/.imps/lex/from "echo" "hello"
  assert_failure || return 1
}

test_from_requires_command() {
  run_spell spells/.imps/lex/from "" "" "/tmp/source"
  assert_failure || return 1
}

run_test_case "from is executable" test_from_is_executable
run_test_case "from prepends source to args" test_from_prepends_source
run_test_case "from requires source" test_from_requires_source
run_test_case "from requires command" test_from_requires_command

finish_tests
