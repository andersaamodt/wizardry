#!/bin/sh
# Behavioral cases (derived from --help):
# - forall prints usage
# - forall fails without a command
# - forall lists each file then indents the command output
# - forall accepts --usage and --help
# - forall keeps working across failures, silent commands, and empty directories
# - forall handles spaces and directories gracefully

set -eu

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/forall" --help
  assert_success || return 1
  assert_output_contains "Usage: forall" || return 1
}

test_usage_alias() {
  run_spell "spells/forall" --usage
  assert_success || return 1
  assert_output_contains "Usage: forall" || return 1
}

forall_requires_command() {
  run_spell "spells/forall"
  assert_failure || return 1
  assert_error_contains "Usage: forall" || return 1
}

forall_runs_command_over_entries() {
  workdir=$(make_tempdir)
  printf 'one' >"$workdir/a.txt"
  printf 'two' >"$workdir/b.txt"
  mkdir -p "$workdir/dir"

  runner="$workdir/echo_arg"
  cat <<'SCRIPT' >"$runner"
#!/bin/sh
echo "run:$1"
SCRIPT
  chmod +x "$runner"

  run_spell_in_dir "$workdir" "spells/forall" "$runner"
  assert_success || return 1
  assert_output_contains "a.txt" || return 1
  assert_output_contains "b.txt" || return 1
  assert_output_contains "dir" || return 1
  assert_output_contains "   run:./a.txt" || return 1
  assert_output_contains "   run:./b.txt" || return 1
  assert_output_contains "   run:./dir" || return 1
}

forall_indents_multiline_output() {
  workdir=$(make_tempdir)
  printf 'first\nsecond\n' >"$workdir/lines.txt"

  run_spell_in_dir "$workdir" "spells/forall" sh -c 'cat "$1"; echo tail' _
  assert_success || return 1
  assert_output_contains "lines.txt" || return 1
  assert_output_contains "   first" || return 1
  assert_output_contains "   second" || return 1
  assert_output_contains "   tail" || return 1
}

forall_handles_spaces() {
  workdir=$(make_tempdir)
  printf 'content\n' >"$workdir/with space.txt"

  run_spell_in_dir "$workdir" "spells/forall" cat
  assert_success || return 1
  assert_output_contains "with space.txt" || return 1
  assert_output_contains "   content" || return 1
}

forall_continues_on_failures() {
  workdir=$(make_tempdir)
  printf 'ok\n' >"$workdir/good"
  printf 'bad\n' >"$workdir/bad"

  run_spell_in_dir "$workdir" "spells/forall" sh -c 'if [ "$1" = "./bad" ]; then echo warn >&2; exit 9; fi; echo pass' _
  assert_success || return 1
  assert_output_contains "good" || return 1
  assert_output_contains "bad" || return 1
  assert_output_contains "   pass" || return 1
  assert_error_contains "warn" || return 1
}

forall_lists_silent_entries() {
  workdir=$(make_tempdir)
  : >"$workdir/quiet.txt"

  run_spell_in_dir "$workdir" "spells/forall" sh -c 'true >/dev/null' _
  assert_success || return 1
  assert_output_contains "quiet.txt" || return 1
  case $OUTPUT in
    *"   "*) TEST_FAILURE_REASON="indentation should be absent for silent commands"; return 1 ;;
  esac
}

forall_handles_directories() {
  workdir=$(make_tempdir)
  mkdir -p "$workdir/dir"
  printf 'data' >"$workdir/file"

  run_spell_in_dir "$workdir" "spells/forall" sh -c 'if [ -d "$1" ]; then echo dir; else echo file; fi' _
  assert_success || return 1
  assert_output_contains "dir" || return 1
  assert_output_contains "file" || return 1
  assert_output_contains "   dir" || return 1
  assert_output_contains "   file" || return 1
}

forall_handles_empty_directory() {
  workdir=$(make_tempdir)
  run_spell_in_dir "$workdir" "spells/forall" sh -c 'echo seen "$1"' _
  assert_success || return 1
  assert_output_contains "./*" || return 1
  assert_output_contains "   seen ./*" || return 1
}

run_test_case "forall prints usage" test_help
run_test_case "forall accepts --usage" test_usage_alias
run_test_case "forall fails without a command" forall_requires_command
run_test_case "forall iterates files and indents output" forall_runs_command_over_entries
run_test_case "forall indents multiline output" forall_indents_multiline_output
run_test_case "forall handles files with spaces" forall_handles_spaces
run_test_case "forall continues when commands fail" forall_continues_on_failures
run_test_case "forall lists files even when command is silent" forall_lists_silent_entries
run_test_case "forall includes directories" forall_handles_directories
run_test_case "forall runs in empty directories" forall_handles_empty_directory

finish_tests
