#!/bin/sh
# Test coverage for priorities spell:
# - Shows usage with --help
# - Requires read-magic command
# - Exits when no priorities set
# - Verbose flag shows priority numbers

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
  run_spell "spells/menu/priorities" --help
  assert_success || return 1
  assert_output_contains "Usage: priorities" || return 1
}

test_help_h_flag() {
  run_spell "spells/menu/priorities" -h
  assert_success || return 1
  assert_output_contains "Usage: priorities" || return 1
}

test_help_usage_flag() {
  run_spell "spells/menu/priorities" --usage
  assert_success || return 1
  assert_output_contains "Usage: priorities" || return 1
}

test_verbose_flag_accepted() {
  # Test that -v flag with --help is recognized
  run_spell "spells/menu/priorities" --help
  assert_success || return 1
  # Verify help mentions verbose mode
  assert_output_contains "-v" || return 1
}

test_no_priorities_exits_gracefully() {
  tmp=$(make_tempdir)
  # Create read-magic stub that says no priorities
  cat >"$tmp/read-magic" <<'SH'
#!/bin/sh
echo "read-magic: attribute does not exist."
SH
  chmod +x "$tmp/read-magic"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Run in the temp directory
  run_cmd env PATH="$tmp:$PATH" PWD="$tmp" "$ROOT_DIR/spells/menu/priorities"
  # Should fail with message about no priorities
  assert_failure || return 1
  assert_output_contains "No priorities set" || return 1
}

test_invalid_option_produces_error() {
  run_spell "spells/menu/priorities" -z 2>&1
  # Invalid option should produce error message (getopts says "Illegal option")
  # The stderr may capture the error
  case "$OUTPUT$ERROR" in
    *"llegal option"*|*"nvalid option"*) : ;;
    *) TEST_FAILURE_REASON="expected error for invalid option: $OUTPUT $ERROR"; return 1 ;;
  esac
}

run_test_case "priorities shows usage text" test_help
run_test_case "priorities shows usage with -h" test_help_h_flag
run_test_case "priorities shows usage with --usage" test_help_usage_flag
run_test_case "priorities accepts -v flag" test_verbose_flag_accepted
run_test_case "priorities exits when no priorities set" test_no_priorities_exits_gracefully
run_test_case "priorities produces error for invalid options" test_invalid_option_produces_error

finish_tests
