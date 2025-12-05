#!/bin/sh
# Tests for category-title imp

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


test_enchant_becomes_enchantment() {
  run_spell "spells/.imps/menu/category-title" "enchant"
  assert_success || return 1
  case "$OUTPUT" in
    *Enchantment*) : ;;
    *) TEST_FAILURE_REASON="expected 'Enchantment' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_mud_becomes_uppercase() {
  run_spell "spells/.imps/menu/category-title" "mud"
  assert_success || return 1
  case "$OUTPUT" in
    *MUD*) : ;;
    *) TEST_FAILURE_REASON="expected 'MUD' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_arcane_capitalizes() {
  run_spell "spells/.imps/menu/category-title" "arcane"
  assert_success || return 1
  case "$OUTPUT" in
    *Arcane*) : ;;
    *) TEST_FAILURE_REASON="expected 'Arcane' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_unknown_capitalizes_first() {
  run_spell "spells/.imps/menu/category-title" "unknown-category"
  assert_success || return 1
  case "$OUTPUT" in
    *Unknown-category*) : ;;
    *) TEST_FAILURE_REASON="expected 'Unknown-category' but got '$OUTPUT'"; return 1 ;;
  esac
}

run_test_case "enchant becomes Enchantment" test_enchant_becomes_enchantment
run_test_case "mud becomes MUD" test_mud_becomes_uppercase
run_test_case "arcane becomes Arcane" test_arcane_capitalizes
run_test_case "unknown categories capitalize first letter" test_unknown_capitalizes_first

finish_tests
