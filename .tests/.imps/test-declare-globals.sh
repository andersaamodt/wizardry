#!/bin/sh
# Tests for the 'declare-globals' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
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


test_declare_globals_is_sourceable() {
  # declare-globals should be sourceable without error
  run_cmd sh -c ". '$ROOT_DIR/spells/.imps/declare-globals'"
  assert_success
}

test_declare_globals_allows_set_u() {
  # After sourcing, scripts with set -u should not fail on declared globals
  run_cmd sh -c "set -u; . '$ROOT_DIR/spells/.imps/declare-globals'; : \"\$WIZARDRY_DIR\""
  assert_success
}

test_declare_globals_sets_empty_defaults() {
  # Globals should default to empty string, not cause unbound variable error
  run_cmd sh -c ". '$ROOT_DIR/spells/.imps/declare-globals'; printf '%s' \"\$WIZARDRY_DIR\""
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected empty default"; return 1; }
}

test_declare_globals_preserves_existing_values() {
  # If a global is already set, declare-globals should preserve it
  run_cmd sh -c "WIZARDRY_DIR=/test/path; . '$ROOT_DIR/spells/.imps/declare-globals'; printf '%s' \"\$WIZARDRY_DIR\""
  assert_success
  [ "$OUTPUT" = "/test/path" ] || { TEST_FAILURE_REASON="expected /test/path but got $OUTPUT"; return 1; }
}

run_test_case "declare-globals is sourceable" test_declare_globals_is_sourceable
run_test_case "declare-globals allows set -u" test_declare_globals_allows_set_u
run_test_case "declare-globals sets empty defaults" test_declare_globals_sets_empty_defaults
run_test_case "declare-globals preserves existing values" test_declare_globals_preserves_existing_values

finish_tests
