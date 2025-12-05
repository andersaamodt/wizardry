#!/bin/sh
# Behavior from --help: memorize spells to the Cast menu.

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


tabbed() {
  # NAME<TAB>NAME (spell name is used as both name and command)
  printf '%s\t%s' "$1" "$1"
}

cast_env() {
  dir=$(mktemp -d "${WIZARDRY_TMPDIR}/cast.XXXXXX")
  mkdir -p "$dir"
  printf 'WIZARDRY_CAST_DIR=%s' "$dir"
}

run_memorize() {
  env_var=$1
  shift
  run_cmd env "$env_var" "$ROOT_DIR/spells/cantrips/memorize" "$@"
}

normalize_output() {
  printf '%s' "$OUTPUT" | tr '\n' '|'
}

memorizes_and_lists_entries() {
  env_var=$(cast_env)
  run_memorize "$env_var" blink
  [ "$STATUS" -eq 0 ] || return 1

  run_memorize "$env_var" list
  expected=$(tabbed "blink")
  case "$(normalize_output)" in
    "$expected"|"$expected|") : ;;
    *) TEST_FAILURE_REASON="unexpected list output: $OUTPUT"; return 1 ;;
  esac
}

pushes_updates_to_front() {
  env_var=$(cast_env)
  run_memorize "$env_var" blink
  run_memorize "$env_var" gust
  run_memorize "$env_var" blink
  run_memorize "$env_var" list
  first_line=$(printf '%s' "$OUTPUT" | head -n1)
  expected=$(printf 'blink\t%s' "blink")
  [ "$first_line" = "$expected" ] || { TEST_FAILURE_REASON="expected blink to be first"; return 1; }
}

prints_cast_path() {
  env_var=$(cast_env)
  file=${env_var#*=}/.memorized
  run_memorize "$env_var" path
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = "$file" ] || { TEST_FAILURE_REASON="unexpected path output"; return 1; }
}

rejects_invalid_args() {
  env_var=$(cast_env)
  run_memorize "$env_var" "bad name"
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected invalid name failure"; return 1; }

  run_memorize "$env_var" list extra
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected usage failure"; return 1; }
}

writes_entries_to_memorized_file() {
  env_var=$(cast_env)
  cast_dir=${env_var#*=}
  run_memorize "$env_var" spark
  # Memorize only adds entries to .memorized file, no wrapper scripts
  [ -f "$cast_dir/.memorized" ] || { TEST_FAILURE_REASON=".memorized file missing"; return 1; }
  grep -q "spark" "$cast_dir/.memorized" || { TEST_FAILURE_REASON="spark not in .memorized"; return 1; }
}

run_test_case "memorizes and lists entries" memorizes_and_lists_entries
run_test_case "pushes updates to the front" pushes_updates_to_front
run_test_case "prints cast path" prints_cast_path
run_test_case "rejects invalid arguments" rejects_invalid_args
run_test_case "writes entries to memorized file" writes_entries_to_memorized_file

shows_help() {
  run_spell spells/cantrips/memorize --help
  assert_success || return 1
  assert_error_contains "Usage:" || return 1
}

run_test_case "memorize shows help" shows_help

# --- Additional test coverage below ---

shows_help_short_flag() {
  run_spell spells/cantrips/memorize -h
  assert_success || return 1
  assert_error_contains "Usage:" || return 1
}

run_test_case "memorize shows help with -h" shows_help_short_flag

prints_cast_dir() {
  env_var=$(cast_env)
  cast_dir=${env_var#*=}
  run_memorize "$env_var" dir
  assert_success || return 1
  [ "$OUTPUT" = "$cast_dir" ] || { TEST_FAILURE_REASON="unexpected dir output: $OUTPUT vs $cast_dir"; return 1; }
}

run_test_case "prints cast dir" prints_cast_dir

no_args_shows_usage() {
  env_var=$(cast_env)
  run_memorize "$env_var"
  assert_failure || return 1
  assert_error_contains "Usage:" || return 1
}

run_test_case "no args shows usage" no_args_shows_usage

unknown_option_error() {
  env_var=$(cast_env)
  run_memorize "$env_var" "--unknown"
  assert_failure || return 1
  assert_error_contains "unknown option" || return 1
}

run_test_case "unknown option shows error" unknown_option_error

empty_list_returns_nothing() {
  env_var=$(cast_env)
  run_memorize "$env_var" list
  assert_success || return 1
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected empty output for empty list"; return 1; }
}

run_test_case "empty list returns nothing" empty_list_returns_nothing

rejects_empty_name() {
  env_var=$(cast_env)
  run_memorize "$env_var" ""
  assert_failure || return 1
  assert_error_contains "names may contain only" || return 1
}

run_test_case "rejects empty name" rejects_empty_name

rejects_name_with_special_chars() {
  env_var=$(cast_env)
  run_memorize "$env_var" "bad/name"
  assert_failure || return 1
  assert_error_contains "names may contain only" || return 1
}

run_test_case "rejects name with special chars" rejects_name_with_special_chars

rejects_name_starting_with_dash() {
  env_var=$(cast_env)
  run_memorize "$env_var" "-badname"
  assert_failure || return 1
  # Names starting with dash are treated as unknown options
  assert_error_contains "unknown option" || return 1
}

run_test_case "rejects name starting with dash" rejects_name_starting_with_dash

allows_valid_name_with_dots() {
  env_var=$(cast_env)
  run_memorize "$env_var" "my.spell"
  assert_success || return 1
  run_memorize "$env_var" list
  assert_output_contains "my.spell" || return 1
}

run_test_case "allows name with dots" allows_valid_name_with_dots

allows_valid_name_with_underscores() {
  env_var=$(cast_env)
  run_memorize "$env_var" "my_spell"
  assert_success || return 1
  run_memorize "$env_var" list
  assert_output_contains "my_spell" || return 1
}

run_test_case "allows name with underscores" allows_valid_name_with_underscores

allows_valid_name_with_dashes() {
  env_var=$(cast_env)
  run_memorize "$env_var" "my-spell"
  assert_success || return 1
  run_memorize "$env_var" list
  assert_output_contains "my-spell" || return 1
}

run_test_case "allows name with dashes" allows_valid_name_with_dashes

# Test recursive sweeps - memorize multiple spells and verify list consistency
recursive_sweep_multiple_spells() {
  env_var=$(cast_env)
  run_memorize "$env_var" spell1
  assert_success || return 1
  run_memorize "$env_var" spell2
  assert_success || return 1
  run_memorize "$env_var" spell3
  assert_success || return 1
  run_memorize "$env_var" spell4
  assert_success || return 1
  run_memorize "$env_var" spell5
  assert_success || return 1

  run_memorize "$env_var" list
  assert_success || return 1

  # Verify all spells are in the list
  assert_output_contains "spell1" || return 1
  assert_output_contains "spell2" || return 1
  assert_output_contains "spell3" || return 1
  assert_output_contains "spell4" || return 1
  assert_output_contains "spell5" || return 1

  # Most recent spell should be first (spell5)
  first_line=$(printf '%s' "$OUTPUT" | head -n1)
  case "$first_line" in
    spell5*) : ;;
    *) TEST_FAILURE_REASON="expected spell5 to be first, got: $first_line"; return 1 ;;
  esac
}

run_test_case "recursive sweep multiple spells" recursive_sweep_multiple_spells

# Test recursive sweeps - re-memorizing moves spell to front
recursive_sweep_reorder() {
  env_var=$(cast_env)
  run_memorize "$env_var" alpha
  run_memorize "$env_var" beta
  run_memorize "$env_var" gamma

  # Re-memorize alpha to move it to the front
  run_memorize "$env_var" alpha

  run_memorize "$env_var" list
  first_line=$(printf '%s' "$OUTPUT" | head -n1)
  case "$first_line" in
    alpha*) : ;;
    *) TEST_FAILURE_REASON="expected alpha to be first after re-memorize"; return 1 ;;
  esac

  # Verify all three are still in the list
  assert_output_contains "alpha" || return 1
  assert_output_contains "beta" || return 1
  assert_output_contains "gamma" || return 1

  # Count lines to ensure no duplicates (add trailing newline for correct wc -l count)
  line_count=$(printf '%s\n' "$OUTPUT" | grep -c .)
  [ "$line_count" -eq 3 ] || { TEST_FAILURE_REASON="expected 3 entries, got: $line_count"; return 1; }
}

run_test_case "recursive sweep reorder" recursive_sweep_reorder

# Test that entries are recorded in .memorized file
memorized_file_content() {
  env_var=$(cast_env)
  cast_dir=${env_var#*=}
  run_memorize "$env_var" testspell
  assert_success || return 1

  # Memorize only records entries in .memorized file (no wrapper scripts)
  [ -f "$cast_dir/.memorized" ] || { TEST_FAILURE_REASON=".memorized file not created"; return 1; }

  # Verify entry is recorded with correct format (name<TAB>name)
  grep -q "testspell	testspell" "$cast_dir/.memorized" || { TEST_FAILURE_REASON="testspell entry not in .memorized"; return 1; }
}

run_test_case "memorized file content" memorized_file_content

# Test WIZARDRY_CAST_FILE environment variable
custom_cast_file() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/custom"
  custom_file="$tmpdir/custom/my-memorized"

  run_cmd env "WIZARDRY_CAST_DIR=$tmpdir" "WIZARDRY_CAST_FILE=$custom_file" \
    "$ROOT_DIR/spells/cantrips/memorize" path
  assert_success || return 1
  [ "$OUTPUT" = "$custom_file" ] || { TEST_FAILURE_REASON="expected custom file path: $custom_file, got: $OUTPUT"; return 1; }
}

run_test_case "custom cast file via WIZARDRY_CAST_FILE" custom_cast_file

# Test MEMORIZE_COMMAND_FILE environment variable (legacy)
legacy_command_file() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/legacy"
  legacy_file="$tmpdir/legacy/legacy-memorized"

  run_cmd env "WIZARDRY_CAST_DIR=$tmpdir" "MEMORIZE_COMMAND_FILE=$legacy_file" \
    "$ROOT_DIR/spells/cantrips/memorize" path
  assert_success || return 1
  [ "$OUTPUT" = "$legacy_file" ] || { TEST_FAILURE_REASON="expected legacy file path"; return 1; }
}

run_test_case "custom cast file via MEMORIZE_COMMAND_FILE" legacy_command_file

# Test SPELLBOOK_DIR
spellbook_dir_test() {
  tmpdir=$(make_tempdir)
  spell_home="$tmpdir/spell-home"

  run_cmd env "SPELLBOOK_DIR=$spell_home" \
    "$ROOT_DIR/spells/cantrips/memorize" dir
  assert_success || return 1
  [ "$OUTPUT" = "$spell_home" ] || { TEST_FAILURE_REASON="expected spell home dir: $spell_home, got: $OUTPUT"; return 1; }
}

run_test_case "SPELLBOOK_DIR" spellbook_dir_test

# Test tilde expansion in WIZARDRY_CAST_DIR
tilde_expansion_cast_dir() {
  tmpdir=$(make_tempdir)
  fake_home="$tmpdir/home"
  mkdir -p "$fake_home/.test-spellbook"

  run_cmd env "HOME=$fake_home" "WIZARDRY_CAST_DIR=~/.test-spellbook" \
    "$ROOT_DIR/spells/cantrips/memorize" dir
  assert_success || return 1
  expected="$fake_home/.test-spellbook"
  [ "$OUTPUT" = "$expected" ] || { TEST_FAILURE_REASON="tilde not expanded: $OUTPUT vs $expected"; return 1; }
}

run_test_case "tilde expansion in WIZARDRY_CAST_DIR" tilde_expansion_cast_dir

# Test path extra args rejected
path_extra_args_rejected() {
  env_var=$(cast_env)
  run_memorize "$env_var" path extra
  assert_failure || return 1
  assert_error_contains "Usage:" || return 1
}

run_test_case "path rejects extra args" path_extra_args_rejected

# Test dir extra args rejected
dir_extra_args_rejected() {
  env_var=$(cast_env)
  run_memorize "$env_var" dir extra
  assert_failure || return 1
  assert_error_contains "Usage:" || return 1
}

run_test_case "dir rejects extra args" dir_extra_args_rejected

# Test memorize spell with multiple args rejected
memorize_extra_args_rejected() {
  env_var=$(cast_env)
  run_memorize "$env_var" spell1 spell2
  assert_failure || return 1
  assert_error_contains "expects exactly one spell name" || return 1
}

run_test_case "memorize rejects extra args" memorize_extra_args_rejected

# Test numeric spell names are allowed
allows_numeric_names() {
  env_var=$(cast_env)
  run_memorize "$env_var" "123"
  assert_success || return 1
  run_memorize "$env_var" list
  assert_output_contains "123" || return 1
}

run_test_case "allows numeric names" allows_numeric_names

# Test mixed alphanumeric names
allows_mixed_alphanumeric() {
  env_var=$(cast_env)
  run_memorize "$env_var" "spell123"
  assert_success || return 1
  run_memorize "$env_var" list
  assert_output_contains "spell123" || return 1
}

run_test_case "allows mixed alphanumeric names" allows_mixed_alphanumeric

finish_tests
