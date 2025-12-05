#!/bin/sh
# Behavioral cases (derived from --help):
# - forall prints usage
# - forall fails without a command
# - forall lists each file then indents the command output
# - forall accepts --usage and --help
# - forall keeps working across failures, silent commands, and empty directories
# - forall handles spaces and directories gracefully

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


test_help() {
  run_spell "spells/arcane/forall" --help
  assert_success || return 1
  assert_output_contains "Usage: forall" || return 1
}

test_usage_alias() {
  run_spell "spells/arcane/forall" --usage
  assert_success || return 1
  assert_output_contains "Usage: forall" || return 1
}

forall_requires_command() {
  run_spell "spells/arcane/forall"
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

  run_spell_in_dir "$workdir" "spells/arcane/forall" "$runner"
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

  run_spell_in_dir "$workdir" "spells/arcane/forall" sh -c 'cat "$1"; echo tail' _
  assert_success || return 1
  assert_output_contains "lines.txt" || return 1
  assert_output_contains "   first" || return 1
  assert_output_contains "   second" || return 1
  assert_output_contains "   tail" || return 1
}

forall_handles_spaces() {
  workdir=$(make_tempdir)
  printf 'content\n' >"$workdir/with space.txt"

  run_spell_in_dir "$workdir" "spells/arcane/forall" cat
  assert_success || return 1
  assert_output_contains "with space.txt" || return 1
  assert_output_contains "   content" || return 1
}

forall_continues_on_failures() {
  workdir=$(make_tempdir)
  printf 'ok\n' >"$workdir/good"
  printf 'bad\n' >"$workdir/bad"

  run_spell_in_dir "$workdir" "spells/arcane/forall" sh -c 'if [ "$1" = "./bad" ]; then echo warn >&2; exit 9; fi; echo pass' _
  assert_success || return 1
  assert_output_contains "good" || return 1
  assert_output_contains "bad" || return 1
  assert_output_contains "   pass" || return 1
  assert_error_contains "warn" || return 1
}

forall_lists_silent_entries() {
  workdir=$(make_tempdir)
  : >"$workdir/quiet.txt"

  run_spell_in_dir "$workdir" "spells/arcane/forall" sh -c 'true >/dev/null' _
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

  run_spell_in_dir "$workdir" "spells/arcane/forall" sh -c 'if [ -d "$1" ]; then echo dir; else echo file; fi' _
  assert_success || return 1
  assert_output_contains "dir" || return 1
  assert_output_contains "file" || return 1
  assert_output_contains "   dir" || return 1
  assert_output_contains "   file" || return 1
}

forall_handles_empty_directory() {
  workdir=$(make_tempdir)
  run_spell_in_dir "$workdir" "spells/arcane/forall" sh -c 'echo seen "$1"' _
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
