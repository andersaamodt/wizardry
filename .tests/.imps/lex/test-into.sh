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

test_into_preserves_target_with_spaces() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/target dir"
  printf '%s\n' "content" > "$tmp/source.txt"

  run_spell spells/.imps/lex/into "cp" "$tmp/source.txt" "$tmp/target dir"
  assert_success || return 1

  if [ ! -f "$tmp/target dir/source.txt" ]; then
    TEST_FAILURE_REASON="File not copied into target directory containing spaces"
    return 1
  fi
}

test_into_sources_parse_for_remaining_words() {
  run_spell spells/.imps/lex/into "echo" "prefix" "target value" "after"
  assert_success || return 1
  assert_output_contains "prefix" || return 1
  assert_output_contains "target value" || return 1
  assert_output_contains "after" || return 1
}

test_into_does_not_glob_command_args() {
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
  run_cmd "$ROOT_DIR/spells/.imps/lex/into" "show-args" "*" "target"
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
    TEST_FAILURE_REASON="into expanded a glob in command arguments"
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
run_test_case "into preserves target with spaces" test_into_preserves_target_with_spaces
run_test_case "into sources parse for remaining words" test_into_sources_parse_for_remaining_words
run_test_case "into does not glob command args" test_into_does_not_glob_command_args
run_test_case "into requires target" test_into_requires_target
run_test_case "into requires command" test_into_requires_command

finish_tests
