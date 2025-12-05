#!/bin/sh
# Tests for scribe-spell spell
# - prints usage with --help
# - rejects unknown options
# - scribes commands non-interactively with 2+ arguments (NAME COMMAND)
# - fails with only 1 argument (needs name and command)
# - creates script file with correct content in ~/.spellbook
# - rejects names with spaces
# - rejects names that conflict with existing commands
# - rejects names of spells already in spellbook or subfolders

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


test_shows_help() {
  run_spell "spells/spellcraft/scribe-spell" --help
  assert_success && assert_output_contains "Usage:"
}

test_shows_help_with_h_flag() {
  run_spell "spells/spellcraft/scribe-spell" -h
  assert_success && assert_output_contains "Usage:"
}

test_noninteractive_scribes_command() {
  case_dir=$(make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/scribe-spell" spark "echo ignite"
  
  assert_success || return 1
  assert_output_contains "Scribed 'spark' to" || return 1
  [ -x "$case_dir/spark" ] || { TEST_FAILURE_REASON="script missing at $case_dir/spark"; return 1; }
  
  # Check script content
  script_content=$(cat "$case_dir/spark")
  case "$script_content" in
    *"echo ignite"*) : ;;
    *) TEST_FAILURE_REASON="script missing command: $script_content"; return 1 ;;
  esac
}

test_fails_with_partial_args() {
  # Only name (needs name and command)
  run_spell "spells/spellcraft/scribe-spell" spark
  assert_failure || return 1
  case "$ERROR" in
    *"Usage:"*) : ;;
    *) TEST_FAILURE_REASON="expected Usage in stderr"; return 1 ;;
  esac
}

test_rejects_invalid_name() {
  case_dir=$(make_tempdir)
  
  # Name with spaces
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/scribe-spell" "spark fire" "echo ignite"
  assert_failure || return 1
  
  # Name starting with dash
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/scribe-spell" "-spark" "echo ignite"
  assert_failure || return 1
}

test_multiword_command() {
  case_dir=$(make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/scribe-spell" test-cmd "echo" "hello" "world"
  
  assert_success || return 1
  [ -x "$case_dir/test-cmd" ] || { TEST_FAILURE_REASON="script missing"; return 1; }
  
  # Check script content contains joined command
  script_content=$(cat "$case_dir/test-cmd")
  case "$script_content" in
    *"echo hello world"*) : ;;
    *) TEST_FAILURE_REASON="multi-word command not joined: $script_content"; return 1 ;;
  esac
}

test_script_is_executable() {
  case_dir=$(make_tempdir)
  
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/scribe-spell" myspell "echo hello"
  
  assert_success || return 1
  [ -x "$case_dir/myspell" ] || { TEST_FAILURE_REASON="script not executable"; return 1; }
  
  # Run the script and check output
  output=$("$case_dir/myspell")
  case "$output" in
    *hello*) : ;;
    *) TEST_FAILURE_REASON="script did not execute correctly: $output"; return 1 ;;
  esac
}

test_rejects_existing_command_name() {
  case_dir=$(make_tempdir)
  
  # Try to create a spell with the same name as 'ls' (a common built-in command)
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/scribe-spell" ls "echo listing"
  
  assert_failure || return 1
  assert_error_contains "conflicts with an existing command" || return 1
  # Verify no spell was created
  [ ! -e "$case_dir/ls" ] || { TEST_FAILURE_REASON="spell file was created despite conflict"; return 1; }
}

test_rejects_duplicate_spell_in_spellbook() {
  case_dir=$(make_tempdir)
  
  # First, create a spell
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/scribe-spell" myuniquespell "echo first"
  
  assert_success || return 1
  
  # Try to create another spell with the same name
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/scribe-spell" myuniquespell "echo second"
  
  assert_failure || return 1
  assert_error_contains "already exists in your spellbook" || return 1
}

test_rejects_duplicate_spell_in_subfolder() {
  case_dir=$(make_tempdir)
  
  # Create a subfolder with a spell in it
  mkdir -p "$case_dir/mycat"
  printf '#!/bin/sh\necho test\n' > "$case_dir/mycat/subspell"
  chmod +x "$case_dir/mycat/subspell"
  
  # Try to create a spell with the same name in the root
  SPELLBOOK_DIR="$case_dir" \
    run_spell "spells/spellcraft/scribe-spell" subspell "echo new"
  
  assert_failure || return 1
  assert_error_contains "already exists in your spellbook" || return 1
}

test_unknown_option() {
  run_spell "spells/spellcraft/scribe-spell" --unknown
  assert_failure || return 1
  assert_error_contains "unknown option" || return 1
}

run_test_case "scribe-spell shows usage" test_shows_help
run_test_case "scribe-spell shows usage with -h" test_shows_help_with_h_flag
run_test_case "scribe-spell rejects unknown option" test_unknown_option
run_test_case "scribe-spell scribes non-interactively" test_noninteractive_scribes_command
run_test_case "scribe-spell fails with partial args" test_fails_with_partial_args
run_test_case "scribe-spell rejects invalid names" test_rejects_invalid_name
run_test_case "scribe-spell joins multi-word commands" test_multiword_command
run_test_case "scribe-spell creates executable scripts" test_script_is_executable
run_test_case "scribe-spell rejects existing command names" test_rejects_existing_command_name
run_test_case "scribe-spell rejects duplicate spell in spellbook" test_rejects_duplicate_spell_in_spellbook
run_test_case "scribe-spell rejects duplicate spell in subfolder" test_rejects_duplicate_spell_in_subfolder

finish_tests
