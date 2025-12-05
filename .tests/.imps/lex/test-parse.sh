#!/bin/sh
# Tests for parse recursive grammar parser

set -eu

# Setup test environment
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
ROOT_DIR=$_test_dir
_sys_path=${PATH:-/usr/local/bin:/usr/bin:/bin}
PATH="$ROOT_DIR/spells:$ROOT_DIR/spells/.imps"
for _d in "$ROOT_DIR/spells/.imps"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
for _d in "$ROOT_DIR/spells"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
PATH="$PATH:$_sys_path"
WIZARDRY_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/wizardry-test.XXXXXX")
export ROOT_DIR PATH WIZARDRY_TMPDIR

# Test state
_pass=0 _fail=0

# Run command and capture output
run_cmd() {
  _o=$(mktemp "$WIZARDRY_TMPDIR/o.XXXXXX"); _e=$(mktemp "$WIZARDRY_TMPDIR/e.XXXXXX")
  STATUS=0; "$@" >"$_o" 2>"$_e" || STATUS=$?
  OUTPUT=$(cat "$_o"); ERROR=$(cat "$_e"); rm -f "$_o" "$_e"
}
run_spell() { _s=$1; shift; run_cmd "$ROOT_DIR/$_s" "$@"; }

# Assertions (call imps with captured state)
assert_success() { test-assert-success "$STATUS" "$ERROR"; }
assert_failure() { test-assert-failure "$STATUS"; }
assert_status() { test-assert-status "$STATUS" "$1" "$ERROR"; }
assert_output_contains() { test-assert-output-contains "$OUTPUT" "$1"; }
assert_error_contains() { test-assert-error-contains "$ERROR" "$1"; }
assert_file_contains() { test-assert-file-contains "$1" "$2"; }
assert_path_exists() { test-assert-path-exists "$1"; }
assert_path_missing() { test-assert-path-missing "$1"; }

# Fixture helpers
make_tempdir() { test-make-tempdir; }
make_fixture() { test-make-fixture; }
write_apt_stub() { test-write-apt-stub "$1"; }
write_sudo_stub() { test-write-sudo-stub "$1"; }
write_command_stub() { test-write-command-stub "$1" "$2"; }
write_pkgin_stub() { test-write-pkgin-stub "$1"; }
provide_basic_tools() { test-provide-basic-tools "$1"; }
link_tools() { test-link-tools "$@"; }

# Test runner
run_test_case() {
  _d=$1; _f=$2
  if "$_f"; then _pass=$((_pass+1)); printf 'PASS %s\n' "$_d"
  else _fail=$((_fail+1)); printf 'FAIL %s\n' "$_d"; fi
}
finish_tests() {
  _t=$((_pass+_fail))
  printf '%s/%s tests passed' "$_pass" "$_t"
  [ "$_fail" -gt 0 ] && printf ' (%s failed)\n' "$_fail" && return 1
  printf '\n'
}


test_parse_imperative_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/parse" ]
}

test_parse_imperative_no_args() {
  run_spell "spells/.imps/lex/parse"
  assert_success || return 1
}

test_parse_imperative_simple_command() {
  run_spell "spells/.imps/lex/parse" echo hello
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

test_parse_imperative_then_chaining() {
  run_spell "spells/.imps/lex/parse" echo first then echo second
  assert_success || return 1
  assert_output_contains "first" || return 1
  assert_output_contains "second" || return 1
}

test_parse_imperative_and_chaining() {
  run_spell "spells/.imps/lex/parse" echo one and echo two
  assert_success || return 1
  assert_output_contains "one" || return 1
  assert_output_contains "two" || return 1
}

test_parse_imperative_or_fallback() {
  run_spell "spells/.imps/lex/parse" false or echo fallback
  assert_success || return 1
  assert_output_contains "fallback" || return 1
}

test_parse_imperative_or_success_skips() {
  run_spell "spells/.imps/lex/parse" true or echo shouldnt_appear
  assert_success || return 1
  # Should NOT contain the fallback message
  case "$OUTPUT" in
    *shouldnt_appear*)
      TEST_FAILURE_REASON="or fallback executed when first command succeeded"
      return 1
      ;;
  esac
}

test_parse_imperative_to_target() {
  tmp=$(make_tempdir)
  echo "source content" > "$tmp/source.txt"
  
  run_spell "spells/.imps/lex/parse" cp "$tmp/source.txt" to "$tmp/dest.txt"
  assert_success || return 1
  
  if [ ! -f "$tmp/dest.txt" ]; then
    TEST_FAILURE_REASON="File not copied to destination using 'to' linking word"
    return 1
  fi
}

test_parse_imperative_into_target() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/target"
  echo "source content" > "$tmp/source.txt"
  
  run_spell "spells/.imps/lex/parse" cp "$tmp/source.txt" into "$tmp/target"
  assert_success || return 1
  
  if [ ! -f "$tmp/target/source.txt" ]; then
    TEST_FAILURE_REASON="File not copied to target directory using 'into' linking word"
    return 1
  fi
}

test_parse_imperative_unknown_command() {
  run_spell "spells/.imps/lex/parse" nonexistent_cmd_xyz
  assert_status 127 || return 1
  # Shell error messages vary, but should indicate the command wasn't found
  case "$ERROR" in
    *"not found"*|*"not exist"*|*"No such"*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="stderr should indicate command not found"
      return 1
      ;;
  esac
}

test_parse_imperative_then_stops_on_failure() {
  run_spell "spells/.imps/lex/parse" false then echo shouldnt_run
  assert_failure || return 1
  # Should NOT contain the second command output
  case "$OUTPUT" in
    *shouldnt_run*)
      TEST_FAILURE_REASON="then continued after failure"
      return 1
      ;;
  esac
}

test_parse_and_then_chains() {
  run_spell "spells/.imps/lex/parse" echo first and then echo second
  assert_success || return 1
  assert_output_contains "first" || return 1
  assert_output_contains "second" || return 1
}

test_parse_and_then_stops_on_failure() {
  run_spell "spells/.imps/lex/parse" false and then echo shouldnt_run
  assert_failure || return 1
  case "$OUTPUT" in
    *shouldnt_run*)
      TEST_FAILURE_REASON="and-then continued after failure"
      return 1
      ;;
  esac
}

# Run all tests
run_test_case "parse is executable" test_parse_imperative_is_executable
run_test_case "parse no args succeeds" test_parse_imperative_no_args
run_test_case "parse runs simple command" test_parse_imperative_simple_command
run_test_case "parse chains with then" test_parse_imperative_then_chaining
run_test_case "parse chains with and" test_parse_imperative_and_chaining
run_test_case "parse or fallback on failure" test_parse_imperative_or_fallback
run_test_case "parse or skips on success" test_parse_imperative_or_success_skips
run_test_case "parse to target reordering" test_parse_imperative_to_target
run_test_case "parse into target reordering" test_parse_imperative_into_target
run_test_case "parse unknown command returns 127" test_parse_imperative_unknown_command
run_test_case "parse then stops on failure" test_parse_imperative_then_stops_on_failure
run_test_case "parse and-then chains" test_parse_and_then_chains
run_test_case "parse and-then stops on failure" test_parse_and_then_stops_on_failure
finish_tests
