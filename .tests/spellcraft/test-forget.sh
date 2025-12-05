#!/bin/sh
# Behavioral coverage for forget:
# - prints usage
# - rejects unknown options
# - removes a spell from the cast menu
# - fails when spell name is missing
# - fails when spell is not memorized

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

run_forget() {
  env_var=$1
  shift
  run_cmd env "$env_var" "$ROOT_DIR/spells/spellcraft/forget" "$@"
}

test_help() {
  run_spell "spells/spellcraft/forget" --help
  assert_success && assert_output_contains "Usage:"
}

test_forget_removes_spell() {
  env_var=$(cast_env)
  # First memorize a spell
  run_memorize "$env_var" myspell
  assert_success
  
  # Verify it's memorized
  run_memorize "$env_var" list
  assert_output_contains "myspell"
  
  # Now forget it
  run_forget "$env_var" myspell
  assert_success
  
  # Verify it's gone
  run_memorize "$env_var" list
  case "$OUTPUT" in
    *myspell*) TEST_FAILURE_REASON="spell should have been forgotten"; return 1 ;;
    *) : ;;
  esac
}

test_forget_requires_name() {
  run_spell "spells/spellcraft/forget"
  assert_failure && assert_error_contains "spell name required"
}

test_forget_fails_when_not_memorized() {
  env_var=$(cast_env)
  run_forget "$env_var" nonexistent
  assert_failure && assert_error_contains "not memorized"
}

test_unknown_option() {
  run_spell "spells/spellcraft/forget" --unknown
  assert_failure && assert_error_contains "unknown option"
}

run_test_case "forget prints usage" test_help
run_test_case "forget rejects unknown option" test_unknown_option
run_test_case "forget removes spell from cast menu" test_forget_removes_spell
run_test_case "forget requires spell name" test_forget_requires_name
run_test_case "forget fails when spell not memorized" test_forget_fails_when_not_memorized

finish_tests
