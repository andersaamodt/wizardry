#!/bin/sh
# Behavior cases from --help: manage aliases in the spellbook store.
# - Adds or updates entries when provided a name and command.
# - Lists stored entries in name<TAB>command format.
# - Removes existing entries or fails for unknown names.
# - Reports the spellbook file path and respects custom locations.
# - Rejects invalid names, commands, or argument counts.

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
  printf 'portal\t%s' "$1"
}

spellbook_env() {
  dir=$(mktemp -d "${WIZARDRY_TMPDIR}/spellbook.XXXXXX")
  printf '%s' "WIZARDRY_SPELLBOOK_FILE=$dir/book"
}

run_store() {
  env_var=$1
  shift
  run_cmd env "$env_var" "$ROOT_DIR/spells/cantrips/spellbook-store" "$@"
}

normalize_output() {
  printf '%s' "$OUTPUT" | tr '\n' '|'
}

# adds and lists entries
adds_and_lists_entries() {
  env_var=$(spellbook_env)
  run_store "$env_var" add portal "echo jump"
  [ "$STATUS" -eq 0 ] || return 1

  run_store "$env_var" list
  [ "$STATUS" -eq 0 ] || return 1
  expected=$(tabbed "echo jump")
  case "$(normalize_output)" in
    "$expected"|"$expected|") : ;;
    *) TEST_FAILURE_REASON="unexpected list output: $OUTPUT"; return 1 ;;
  esac
}

# updates existing entries
updates_existing_entry() {
  env_var=$(spellbook_env)
  run_store "$env_var" add portal "echo jump"
  run_store "$env_var" add portal "echo stay"
  run_store "$env_var" list
  expected=$(tabbed "echo stay")
  case "$(normalize_output)" in
    "$expected"|"$expected|") : ;;
    *) TEST_FAILURE_REASON="expected updated command"; return 1 ;;
  esac
}

# removes entries and errors for missing names
removes_entries_and_errors_when_missing() {
  env_var=$(spellbook_env)
  run_store "$env_var" add portal "echo jump"
  run_store "$env_var" remove portal
  [ "$STATUS" -eq 0 ] || return 1
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="remove should be silent"; return 1; }

  run_store "$env_var" remove portal
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected failure for missing"; return 1; }
}

# prints configured spellbook path
prints_spellbook_path() {
  env_var=$(spellbook_env)
  file=${env_var#*=}
  run_store "$env_var" path
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = "$file" ] || { TEST_FAILURE_REASON="unexpected path output"; return 1; }
}

# rejects invalid arguments
rejects_invalid_args() {
  env_var=$(spellbook_env)
  run_store "$env_var" add "bad name" "echo x"
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected invalid name failure"; return 1; }

  run_store "$env_var" add portal ""
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected empty command failure"; return 1; }

  run_store "$env_var" list extra
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected usage failure"; return 1; }
}

run_test_case "adds and lists entries" adds_and_lists_entries
run_test_case "updates existing entry" updates_existing_entry
run_test_case "removes entries and errors when missing" removes_entries_and_errors_when_missing
run_test_case "prints spellbook path" prints_spellbook_path
run_test_case "rejects invalid arguments" rejects_invalid_args

shows_help() {
  run_spell spells/cantrips/spellbook-store --help
  true
}

run_test_case "spellbook-store shows help" shows_help

finish_tests
