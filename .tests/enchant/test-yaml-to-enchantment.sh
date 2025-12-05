#!/bin/sh
# Behavioral cases (derived from --help):
# - yaml-to-enchantment prints usage
# - validates argument count and file existence
# - fails when YAML header is missing
# - restores attributes using available helpers and trims the header
# - reports missing helpers
# - stops on attribute write failures

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


make_stub_dir() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/stubs"
  printf '%s\n' "$tmpdir/stubs"
}

test_help() {
  run_spell "spells/enchant/yaml-to-enchantment" --help
  assert_success && assert_output_contains "Usage: yaml-to-enchantment"
}

test_argument_validation() {
  run_spell "spells/enchant/yaml-to-enchantment"
  assert_failure && assert_error_contains "incorrect number of arguments"

  run_spell "spells/enchant/yaml-to-enchantment" one two
  assert_failure && assert_error_contains "incorrect number of arguments"
}

test_missing_file() {
  run_spell "spells/enchant/yaml-to-enchantment" "$WIZARDRY_TMPDIR/missing"
  assert_failure && assert_error_contains "file does not exist"
}

test_requires_header() {
  tmpfile="$WIZARDRY_TMPDIR/no-header"
  printf 'content\n' >"$tmpfile"
  run_spell "spells/enchant/yaml-to-enchantment" "$tmpfile"
  assert_failure && assert_error_contains "does not have a YAML header"
}

test_restores_attributes_and_strips_header() {
  stub_dir=$(make_stub_dir)
  cat >"$stub_dir/attr" <<'STUB'
#!/bin/sh
if [ "$1" = "-s" ]; then
  printf '%s: %s\n' "$2" "$4" >>"${WIZARDRY_TMPDIR}/restored.attrs"
fi
exit 0
STUB
  chmod +x "$stub_dir/attr"

  tmpfile="$WIZARDRY_TMPDIR/headered"
  cat >"$tmpfile" <<'FILE'
---
user.alpha: sun
user.beta: moon
---
body
FILE

  PATH="$stub_dir:$PATH" run_spell "spells/enchant/yaml-to-enchantment" "$tmpfile"
  assert_success
  restored=$(cat "$WIZARDRY_TMPDIR/restored.attrs")
  expected="user.alpha: sun
user.beta: moon"
  [ "$restored" = "$expected" ] || { TEST_FAILURE_REASON="unexpected restored attrs: $restored"; return 1; }
  body=$(cat "$tmpfile")
  [ "$body" = "body" ] || { TEST_FAILURE_REASON="header not stripped"; return 1; }
}

test_reports_missing_helpers() {
  tmpfile="$WIZARDRY_TMPDIR/headered-missing"
  cat >"$tmpfile" <<'FILE'
---
user.alpha: sky
---
spell
FILE
  # remove helper availability while keeping core utilities
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:/usr/bin:/bin" run_spell "spells/enchant/yaml-to-enchantment" "$tmpfile"
  assert_failure && assert_error_contains "requires attr, setfattr, or xattr"
}

test_fails_on_attribute_error() {
  stub_dir=$(make_stub_dir)
  cat >"$stub_dir/attr" <<'STUB'
#!/bin/sh
exit 1
STUB
  chmod +x "$stub_dir/attr"

  tmpfile="$WIZARDRY_TMPDIR/headered-fail"
  cat >"$tmpfile" <<'FILE'
---
user.alpha: fail
---
body
FILE

  PATH="$stub_dir:$PATH" run_spell "spells/enchant/yaml-to-enchantment" "$tmpfile"
  assert_failure && assert_error_contains "failed to set attribute"
}

run_test_case "yaml-to-enchantment prints usage" test_help
run_test_case "yaml-to-enchantment validates arguments" test_argument_validation
run_test_case "yaml-to-enchantment fails for missing files" test_missing_file
run_test_case "yaml-to-enchantment requires YAML header" test_requires_header
run_test_case "yaml-to-enchantment restores attributes and strips header" test_restores_attributes_and_strips_header
run_test_case "yaml-to-enchantment reports missing helpers" test_reports_missing_helpers
run_test_case "yaml-to-enchantment fails when helper errors" test_fails_on_attribute_error
finish_tests
