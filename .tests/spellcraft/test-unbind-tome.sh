#!/bin/sh
# Behavioral cases (derived from --help):
# - unbind-tome requires a file argument
# - unbind-tome splits the tome into sanitised files
# - unbind-tome prints helpful usage text
# - unbind-tome refuses non-file inputs and existing destination folders
# - unbind-tome invents names for blank pages

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


unbind_shows_usage() {
  run_spell "spells/spellcraft/unbind-tome" --help
  assert_success || return 1
  assert_output_contains "Usage: unbind-tome" || return 1
  assert_output_contains "Split a bound tome" || return 1
}

require_arg_for_unbind() {
  run_spell "spells/spellcraft/unbind-tome"
  assert_failure || return 1
  assert_error_contains "unbind-tome: file path required." || return 1
}

unbind_requires_a_file() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/dir"

  run_spell "spells/spellcraft/unbind-tome" "$tmpdir/dir"
  assert_failure || return 1
  assert_error_contains "is not a file" || return 1
}

unbind_splits_into_pages() {
  workdir=$(make_tempdir)
  cat <<'STORY' >"$workdir/story.txt"
First page
Symbols & sigils
Trailing space
STORY

  oldpwd=$(pwd)
  cd "$workdir"
  run_spell "spells/spellcraft/unbind-tome" "story.txt"
  cd "$oldpwd"
  assert_success || return 1

  pieces_dir="$workdir/story"
  assert_path_exists "$pieces_dir" || return 1
  assert_path_exists "$pieces_dir/First_page" || return 1
  assert_path_exists "$pieces_dir/Symbols__sigils" || return 1
  assert_path_exists "$pieces_dir/Trailing_space" || return 1
}

unbind_avoids_clobbering_existing_folder() {
  workdir=$(make_tempdir)
  mkdir -p "$workdir/story" "$workdir/story1"
  printf 'First\nSecond\n' >"$workdir/story.txt"

  oldpwd=$(pwd)
  cd "$workdir"
  run_spell "spells/spellcraft/unbind-tome" "story.txt"
  cd "$oldpwd"
  assert_success || return 1

  assert_path_exists "$workdir/story2" || return 1
  assert_path_exists "$workdir/story2/First" || return 1
  assert_path_exists "$workdir/story2/Second" || return 1
}

unbind_names_blank_pages() {
  workdir=$(make_tempdir)
  cat <<'STORY' >"$workdir/blanky.txt"

Titled page

STORY

  RUN_CMD_WORKDIR="$workdir" run_spell "spells/spellcraft/unbind-tome" "$workdir/blanky.txt"
  assert_success || return 1

  assert_path_exists "$workdir/blanky/page_1" || return 1
  assert_path_exists "$workdir/blanky/Titled_page" || return 1
  assert_path_exists "$workdir/blanky/page_3" || return 1
}

run_test_case "unbind-tome requires a file argument" require_arg_for_unbind
run_test_case "unbind-tome splits the tome into sanitised files" unbind_splits_into_pages
run_test_case "unbind-tome shows usage text" unbind_shows_usage
run_test_case "unbind-tome refuses non-file inputs" unbind_requires_a_file
run_test_case "unbind-tome avoids clobbering existing folders" unbind_avoids_clobbering_existing_folder
run_test_case "unbind-tome invents names for blank pages" unbind_names_blank_pages

finish_tests
