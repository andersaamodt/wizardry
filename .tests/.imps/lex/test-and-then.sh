#!/bin/sh
# Tests for the 'and-then' linking word imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_and_then_is_executable() {
  skip-if-compiled || return $?
  [ -x "$ROOT_DIR/spells/.imps/lex/and-then" ]
}

test_and_then_continues_on_success() {
  skip-if-compiled || return $?
  run_spell spells/.imps/lex/and-then "true" "" echo hello
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

test_and_then_stops_on_failure() {
  skip-if-compiled || return $?
  run_spell spells/.imps/lex/and-then "false" "" echo shouldnt_run
  assert_failure || return 1
  case "$OUTPUT" in
    *shouldnt_run*)
      TEST_FAILURE_REASON="and-then continued after failure"
      return 1
      ;;
  esac
}

test_and_then_no_prior_command() {
  skip-if-compiled || return $?
  run_spell spells/.imps/lex/and-then "" "" echo hello
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

test_and_then_does_not_glob_prior_args() {
  skip-if-compiled || return $?

  tmpdir=$(make_tempdir)
  workdir="$tmpdir/work"
  stubdir="$tmpdir/bin"
  mkdir -p "$workdir" "$stubdir"
  : > "$workdir/expanded"

  cat > "$stubdir/show-args" <<'EOF'
#!/bin/sh
printf 'arg1=%s\n' "${1-missing}"
EOF
  chmod +x "$stubdir/show-args"

  saved_path=$PATH
  saved_workdir=${RUN_CMD_WORKDIR-}
  PATH="$stubdir:$PATH"
  RUN_CMD_WORKDIR=$workdir
  export PATH RUN_CMD_WORKDIR
  run_cmd "$ROOT_DIR/spells/.imps/lex/and-then" "show-args" "*"
  PATH=$saved_path
  export PATH
  if [ -n "$saved_workdir" ]; then
    RUN_CMD_WORKDIR=$saved_workdir
    export RUN_CMD_WORKDIR
  else
    unset RUN_CMD_WORKDIR
  fi

  assert_success || return 1
  assert_output_contains "arg1=*" || return 1
  if printf '%s' "$OUTPUT" | grep -q "expanded"; then
    TEST_FAILURE_REASON="and-then expanded a glob in prior command arguments"
    return 1
  fi
}

run_test_case "and-then is executable" test_and_then_is_executable
run_test_case "and-then continues on success" test_and_then_continues_on_success
run_test_case "and-then stops on failure" test_and_then_stops_on_failure
run_test_case "and-then with no prior command" test_and_then_no_prior_command
run_test_case "and-then does not glob prior command args" test_and_then_does_not_glob_prior_args

finish_tests
