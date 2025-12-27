#!/bin/sh
# Behavioral cases (derived from --help):
# - forall prints usage
# - forall fails without a command
# - forall lists each file then indents the command output
# - forall accepts --usage and --help
# - forall keeps working across failures, silent commands, and empty directories
# - forall handles spaces and directories gracefully

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/arcane/forall" --help
  _assert_success || return 1
  _assert_output_contains "Usage: forall" || return 1
}

test_usage_alias() {
  _run_spell "spells/arcane/forall" --usage
  _assert_success || return 1
  _assert_output_contains "Usage: forall" || return 1
}

forall_requires_command() {
  _run_spell "spells/arcane/forall"
  _assert_failure || return 1
  _assert_error_contains "Usage: forall" || return 1
}

forall_runs_command_over_entries() {
  workdir=$(_make_tempdir)
  printf 'one' >"$workdir/a.txt"
  printf 'two' >"$workdir/b.txt"
  mkdir -p "$workdir/dir"

  runner="$workdir/echo_arg"
  cat <<'SCRIPT' >"$runner"
#!/bin/sh
echo "run:$1"
SCRIPT
  chmod +x "$runner"

  _run_spell_in_dir "$workdir" "spells/arcane/forall" "$runner"
  _assert_success || return 1
  _assert_output_contains "a.txt" || return 1
  _assert_output_contains "b.txt" || return 1
  _assert_output_contains "dir" || return 1
  _assert_output_contains "   run:./a.txt" || return 1
  _assert_output_contains "   run:./b.txt" || return 1
  _assert_output_contains "   run:./dir" || return 1
}

forall_indents_multiline_output() {
  workdir=$(_make_tempdir)
  printf 'first\nsecond\n' >"$workdir/lines.txt"

  _run_spell_in_dir "$workdir" "spells/arcane/forall" sh -c 'cat "$1"; echo tail' _
  _assert_success || return 1
  _assert_output_contains "lines.txt" || return 1
  _assert_output_contains "   first" || return 1
  _assert_output_contains "   second" || return 1
  _assert_output_contains "   tail" || return 1
}

forall_handles_spaces() {
  workdir=$(_make_tempdir)
  printf 'content\n' >"$workdir/with space.txt"

  _run_spell_in_dir "$workdir" "spells/arcane/forall" cat
  _assert_success || return 1
  _assert_output_contains "with space.txt" || return 1
  _assert_output_contains "   content" || return 1
}

forall_continues_on_failures() {
  workdir=$(_make_tempdir)
  printf 'ok\n' >"$workdir/good"
  printf 'bad\n' >"$workdir/bad"

  _run_spell_in_dir "$workdir" "spells/arcane/forall" sh -c 'if [ "$1" = "./bad" ]; then echo warn >&2; exit 9; fi; echo pass' _
  _assert_success || return 1
  _assert_output_contains "good" || return 1
  _assert_output_contains "bad" || return 1
  _assert_output_contains "   pass" || return 1
  _assert_error_contains "warn" || return 1
}

forall_lists_silent_entries() {
  workdir=$(_make_tempdir)
  : >"$workdir/quiet.txt"

  _run_spell_in_dir "$workdir" "spells/arcane/forall" sh -c 'true >/dev/null' _
  _assert_success || return 1
  _assert_output_contains "quiet.txt" || return 1
  case $OUTPUT in
    *"   "*) TEST_FAILURE_REASON="indentation should be absent for silent commands"; return 1 ;;
  esac
}

forall_handles_directories() {
  workdir=$(_make_tempdir)
  mkdir -p "$workdir/dir"
  printf 'data' >"$workdir/file"

  _run_spell_in_dir "$workdir" "spells/arcane/forall" sh -c 'if [ -d "$1" ]; then echo dir; else echo file; fi' _
  _assert_success || return 1
  _assert_output_contains "dir" || return 1
  _assert_output_contains "file" || return 1
  _assert_output_contains "   dir" || return 1
  _assert_output_contains "   file" || return 1
}

forall_handles_empty_directory() {
  workdir=$(_make_tempdir)
  _run_spell_in_dir "$workdir" "spells/arcane/forall" sh -c 'echo seen "$1"' _
  _assert_success || return 1
  _assert_output_contains "./*" || return 1
  _assert_output_contains "   seen ./*" || return 1
}

# Run all tests
_run_test_case "forall prints usage" test_help
_run_test_case "forall accepts --usage flag" test_usage_alias
_run_test_case "forall requires command" forall_requires_command
_run_test_case "forall runs command over entries" forall_runs_command_over_entries
_run_test_case "forall runs commands on entries with spaces" forall_handles_spaces
_run_test_case "forall continues on failures" forall_continues_on_failures
_run_test_case "forall lists silent entries" forall_lists_silent_entries
_run_test_case "forall handles directories" forall_handles_directories
_run_test_case "forall handles empty directory" forall_handles_empty_directory

_finish_tests
