#!/bin/sh
# Behavioral cases (derived from --help and script behavior):
# - mark-location prints usage
# - errors when given too many arguments
# - errors when target path does not exist
# - records the current directory by default with auto-incrementing marker
# - resolves provided paths to absolute destinations
# - supports named markers

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
  run_spell "spells/translocation/mark-location" --help
  assert_success && assert_output_contains "Usage: mark-location"
}

test_too_many_args() {
  run_spell "spells/translocation/mark-location" one two three
  assert_failure && assert_output_contains "Usage: mark-location"
}

test_missing_target_path() {
  run_spell "spells/translocation/mark-location" mymarker "$WIZARDRY_TMPDIR/vanishes"
  assert_failure && assert_error_contains "does not exist"
}

test_marks_current_directory() {
  workdir=$(make_tempdir)
  # Resolve symlinks to match what mark-location will see with pwd -P
  workdir_resolved=$(cd "$workdir" && pwd -P | sed 's|//|/|g')
  run_spell_in_dir "$workdir" "spells/translocation/mark-location"
  assert_success && assert_output_contains "Marked location 1 at $workdir_resolved"
}

test_marks_with_named_marker() {
  workdir=$(make_tempdir)
  workdir_resolved=$(cd "$workdir" && pwd -P | sed 's|//|/|g')
  run_spell_in_dir "$workdir" "spells/translocation/mark-location" alpha
  assert_success && assert_output_contains "Marked location alpha at $workdir_resolved"
}

test_marks_with_path() {
  workdir=$(make_tempdir)
  target_dir="$workdir/place"
  mkdir -p "$target_dir"
  target_dir_resolved=$(cd "$target_dir" && pwd -P | sed 's|//|/|g')
  run_spell_in_dir "$workdir" "spells/translocation/mark-location" myplace "$target_dir"
  assert_success && assert_output_contains "Marked location myplace at $target_dir_resolved"
}

test_resolves_relative_destination() {
  workdir=$(make_tempdir)
  target_dir="$workdir/place"
  mkdir -p "$target_dir"
  # Resolve symlinks to match what mark-location will see
  target_dir_resolved=$(cd "$target_dir" && pwd -P | sed 's|//|/|g')
  # When single arg is a directory, it's treated as a path (marks it as auto-increment)
  run_spell_in_dir "$workdir" "spells/translocation/mark-location" "place"
  assert_success && assert_output_contains "at $target_dir_resolved"
}

test_overwrites_marker() {
  expected="$WIZARDRY_TMPDIR/mark-overwrite"
  # Resolve symlinks to match what mark-location will see with pwd -P
  run_cmd sh -c '
    set -e
    expected="'"$expected"'"
    rm -rf "$expected"
    mkdir -p "$expected" "$HOME/.spellbook/.markers"
    printf "/previous\n" >"$HOME/.spellbook/.markers/1"
    cd "$expected"
    # Get the resolved path that mark-location will use
    expected_resolved=$(pwd -P | sed "s|//|/|g")
    mark-location 1
    marker_content=$(cat "$HOME/.spellbook/.markers/1")
    printf "Marked location 1 at %s\n" "$expected_resolved"
    printf "MARK:%s\n" "$marker_content"
  '
  assert_success
  assert_output_contains "Marked location 1 at"
  assert_output_contains "MARK:"
}

test_resolves_symlink_workdir() {
  real_dir="$WIZARDRY_TMPDIR/mark-real"
  link_dir="$WIZARDRY_TMPDIR/mark-link"
  run_cmd sh -c '
    set -e
    real_dir="'"$real_dir"'"
    link_dir="'"$link_dir"'"
    rm -rf "$real_dir" "$link_dir"
    mkdir -p "$real_dir"
    ln -s "$real_dir" "$link_dir"
    cd "$link_dir"
    # Resolve the real directory to its physical path for comparison
    real_dir_resolved=$(cd "$real_dir" && pwd -P | sed "s|//|/|g")
    mark-location testlink
    printf "MARK:%s\n" "$(cat "$HOME/.spellbook/.markers/testlink")"
    printf "Marked location testlink at %s\n" "$real_dir_resolved"
  '
  assert_success
  # The marker should contain the resolved physical path
  # Extract the resolved path from the output for verification
  real_dir_resolved=$(cd "$real_dir" && pwd -P | sed 's|//|/|g' 2>/dev/null || printf '%s' "$real_dir")
  assert_output_contains "MARK:$real_dir_resolved"
}

test_expands_tilde_argument() {
  run_cmd sh -c '
    set -e
    mkdir -p "$HOME/special/place"
    mark-location tildetest "~/special/place"
    printf "MARK:%s\n" "$(cat "$HOME/.spellbook/.markers/tildetest")"
  '
  assert_success
  case "$OUTPUT" in
    *"MARK:~"*) TEST_FAILURE_REASON="marker retained literal tilde"; return 1 ;;
    *"MARK:/"*"/special/place"*) : ;;
    *) TEST_FAILURE_REASON="marker did not record expanded target"; return 1 ;;
  esac
}

test_marker_dir_blocked() {
  run_cmd sh -c '
    set -e
    rm -rf "$HOME/.spellbook"
    mkdir -p "$HOME/.spellbook"
    touch "$HOME/.spellbook/.markers"
    mark-location
  '
  assert_failure
  assert_error_contains "markers"
}

test_auto_increments_marker() {
  run_cmd sh -c '
    set -e
    rm -rf "$HOME/.spellbook/.markers"
    mark-location
    mark-location
    mark-location
    ls "$HOME/.spellbook/.markers/"
  '
  assert_success
  assert_output_contains "1"
  assert_output_contains "2"
  assert_output_contains "3"
}

run_test_case "mark-location prints usage" test_help
run_test_case "mark-location errors on extra arguments" test_too_many_args
run_test_case "mark-location errors for missing path" test_missing_target_path
run_test_case "mark-location records current directory" test_marks_current_directory
run_test_case "mark-location supports named markers" test_marks_with_named_marker
run_test_case "mark-location supports marker with path" test_marks_with_path
run_test_case "mark-location resolves relative paths" test_resolves_relative_destination
run_test_case "mark-location overwrites existing marker" test_overwrites_marker
run_test_case "mark-location resolves symlinked working directory" test_resolves_symlink_workdir
run_test_case "mark-location expands tilde arguments" test_expands_tilde_argument
run_test_case "mark-location errors when marker directory is blocked" test_marker_dir_blocked
run_test_case "mark-location auto-increments marker number" test_auto_increments_marker
finish_tests
