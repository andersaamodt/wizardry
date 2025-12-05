#!/bin/sh
# Tests for the 'is-installable' imp

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


# Create a temp spell with an install() function
create_installable_spell() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/spell.XXXXXX")
  cat > "$tmpfile" <<'SPELL'
#!/bin/sh
# A test spell with install function

install() {
  echo "Installing..."
}

echo "Running..."
SPELL
  chmod +x "$tmpfile"
  printf '%s' "$tmpfile"
}

# Create a temp spell without an install() function
create_noninstallable_spell() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/spell.XXXXXX")
  cat > "$tmpfile" <<'SPELL'
#!/bin/sh
# A test spell without install function

echo "Running..."
SPELL
  chmod +x "$tmpfile"
  printf '%s' "$tmpfile"
}

test_detects_installable_spell() {
  spell=$(create_installable_spell)
  run_spell spells/.imps/menu/is-installable "$spell"
  rm -f "$spell"
  assert_success
}

test_rejects_noninstallable_spell() {
  spell=$(create_noninstallable_spell)
  run_spell spells/.imps/menu/is-installable "$spell"
  rm -f "$spell"
  assert_failure
}

test_fails_for_missing_file() {
  run_spell spells/.imps/menu/is-installable "/nonexistent/path/to/spell"
  assert_failure
}

test_fails_for_empty_argument() {
  run_spell spells/.imps/menu/is-installable ""
  assert_failure
}

test_fails_for_no_argument() {
  run_spell spells/.imps/menu/is-installable
  assert_failure
}

test_detects_indented_install_function() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/spell.XXXXXX")
  cat > "$tmpfile" <<'SPELL'
#!/bin/sh
# A test spell with indented install function

  install() {
    echo "Installing..."
  }
SPELL
  chmod +x "$tmpfile"
  run_spell spells/.imps/menu/is-installable "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

run_test_case "is-installable detects spell with install()" test_detects_installable_spell
run_test_case "is-installable rejects spell without install()" test_rejects_noninstallable_spell
run_test_case "is-installable fails for missing file" test_fails_for_missing_file
run_test_case "is-installable fails for empty argument" test_fails_for_empty_argument
run_test_case "is-installable fails for no argument" test_fails_for_no_argument
run_test_case "is-installable detects indented install function" test_detects_indented_install_function

finish_tests
