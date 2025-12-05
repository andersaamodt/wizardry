#!/bin/sh
# erase-spell test coverage:
# - shows usage with --help
# - rejects unknown options
# - requires spell name argument
# - errors when spell not found
# - --force skips confirmation and deletes spell

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


make_spellbook_dir() {
  dir=$(mktemp -d "$WIZARDRY_TMPDIR/spellbook.XXXXXX") || exit 1
  printf '%s\n' "$dir"
}

test_shows_usage_with_help() {
  run_spell "spells/spellcraft/erase-spell" --help
  assert_success || return 1
  case "$OUTPUT" in
    *"Usage: erase-spell"*) : ;;
    *) TEST_FAILURE_REASON="help text should show usage: $OUTPUT"; return 1 ;;
  esac
}

test_requires_spell_name() {
  run_spell "spells/spellcraft/erase-spell"
  assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"Usage:"*) : ;;
    *) TEST_FAILURE_REASON="should show usage when no arguments: $OUTPUT$ERROR"; return 1 ;;
  esac
}

test_errors_when_spell_not_found() {
  spellbook_dir=$(make_spellbook_dir)
  SPELLBOOK_DIR="$spellbook_dir" run_spell "spells/spellcraft/erase-spell" nonexistent
  assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"not found"*) : ;;
    *) TEST_FAILURE_REASON="should report spell not found: $OUTPUT$ERROR"; return 1 ;;
  esac
}

test_force_deletes_spell_without_confirmation() {
  spellbook_dir=$(make_spellbook_dir)
  # Create a custom spell
  printf '#!/bin/sh\necho hello\n' >"$spellbook_dir/test-spell"
  chmod +x "$spellbook_dir/test-spell"
  # Delete with --force
  SPELLBOOK_DIR="$spellbook_dir" run_spell "spells/spellcraft/erase-spell" --force test-spell
  assert_success || return 1
  case "$OUTPUT" in
    *"Erased spell"*) : ;;
    *) TEST_FAILURE_REASON="should confirm deletion: $OUTPUT"; return 1 ;;
  esac
  # Verify file is removed
  if [ -f "$spellbook_dir/test-spell" ]; then
    TEST_FAILURE_REASON="spell file should be deleted"
    return 1
  fi
}

test_force_deletes_spell_in_subfolder() {
  spellbook_dir=$(make_spellbook_dir)
  mkdir -p "$spellbook_dir/category"
  # Create a custom spell in subfolder
  printf '#!/bin/sh\necho hello\n' >"$spellbook_dir/category/sub-spell"
  chmod +x "$spellbook_dir/category/sub-spell"
  # Delete with --force
  SPELLBOOK_DIR="$spellbook_dir" run_spell "spells/spellcraft/erase-spell" --force sub-spell
  assert_success || return 1
  # Verify file is removed
  if [ -f "$spellbook_dir/category/sub-spell" ]; then
    TEST_FAILURE_REASON="spell file should be deleted"
    return 1
  fi
}

test_unknown_option() {
  run_spell "spells/spellcraft/erase-spell" --unknown
  assert_failure || return 1
  assert_error_contains "unknown option" || return 1
}

run_test_case "erase-spell shows usage with --help" test_shows_usage_with_help
run_test_case "erase-spell rejects unknown option" test_unknown_option
run_test_case "erase-spell requires spell name" test_requires_spell_name
run_test_case "erase-spell errors when spell not found" test_errors_when_spell_not_found
run_test_case "erase-spell --force deletes without confirmation" test_force_deletes_spell_without_confirmation
run_test_case "erase-spell --force deletes spell in subfolder" test_force_deletes_spell_in_subfolder

finish_tests
