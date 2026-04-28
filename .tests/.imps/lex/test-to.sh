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
  tmp=$(make_tempdir)
  echo "content" > "$tmp/source.txt"
  
  run_spell spells/.imps/lex/to "cp" "$tmp/source.txt" "$tmp/dest.txt"
  assert_success || return 1
  
  if [ ! -f "$tmp/dest.txt" ]; then
    TEST_FAILURE_REASON="File not copied to destination"
    return 1
  fi
}

test_to_preserves_target_with_spaces() {
  tmp=$(make_tempdir)
  printf '%s\n' "content" > "$tmp/source.txt"

  run_spell spells/.imps/lex/to "cp" "$tmp/source.txt" "$tmp/dest file.txt"
  assert_success || return 1

  if [ ! -f "$tmp/dest file.txt" ]; then
    TEST_FAILURE_REASON="File not copied to destination containing spaces"
    return 1
  fi
}

test_to_sources_parse_for_remaining_words() {
  run_spell spells/.imps/lex/to "echo" "prefix" "target value" "after"
  assert_success || return 1
  assert_output_contains "prefix" || return 1
  assert_output_contains "target value" || return 1
  assert_output_contains "after" || return 1
}

test_to_does_not_glob_command_args() {
  tmpdir=$(make_tempdir)
  workdir="$tmpdir/work"
  stubdir="$tmpdir/bin"
  mkdir -p "$workdir" "$stubdir"
  : > "$workdir/expanded"

  cat > "$stubdir/show-args" <<'EOF'
#!/bin/sh
printf 'args: [%s]\n' "$*"
EOF
  chmod +x "$stubdir/show-args"

  saved_path=$PATH
  saved_workdir=${RUN_CMD_WORKDIR-}
  PATH="$stubdir:$PATH"
  RUN_CMD_WORKDIR=$workdir
  export PATH RUN_CMD_WORKDIR
  run_cmd "$ROOT_DIR/spells/.imps/lex/to" "show-args" "*" "target"
  PATH=$saved_path
  export PATH
  if [ -n "$saved_workdir" ]; then
    RUN_CMD_WORKDIR=$saved_workdir
    export RUN_CMD_WORKDIR
  else
    unset RUN_CMD_WORKDIR
  fi

  assert_success || return 1
  assert_output_contains "args: [* target]" || return 1
  if printf '%s' "$OUTPUT" | grep -q "expanded"; then
    TEST_FAILURE_REASON="to expanded a glob in command arguments"
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
run_test_case "to preserves target with spaces" test_to_preserves_target_with_spaces
run_test_case "to sources parse for remaining words" test_to_sources_parse_for_remaining_words
run_test_case "to does not glob command args" test_to_does_not_glob_command_args
run_test_case "to requires target" test_to_requires_target
run_test_case "to requires command" test_to_requires_command

finish_tests
