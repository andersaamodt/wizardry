#!/bin/sh
# Behavioral cases (derived from --help):
# - enchantment-to-yaml prints usage
# - validates argument count and file existence
# - fails when no attributes are present
# - writes YAML with keys and values using available helpers and clears attributes
# - reports missing helpers when clearing is impossible

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
  run_spell "spells/enchant/enchantment-to-yaml" --help
  assert_success && assert_output_contains "Usage: enchantment-to-yaml"
}

test_argument_validation() {
  run_spell "spells/enchant/enchantment-to-yaml"
  assert_failure && assert_error_contains "incorrect number of arguments"

  run_spell "spells/enchant/enchantment-to-yaml" one two
  assert_failure && assert_error_contains "incorrect number of arguments"
}

test_missing_file() {
  run_spell "spells/enchant/enchantment-to-yaml" "$WIZARDRY_TMPDIR/missing"
  assert_failure && assert_error_contains "file does not exist"
}

test_requires_attributes() {
  stub_dir=$(make_stub_dir)
  cat >"$stub_dir/xattr" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub_dir/xattr"

  target="$WIZARDRY_TMPDIR/plain"
  printf 'body\n' >"$target"
  PATH="$stub_dir:$PATH" run_spell "spells/enchant/enchantment-to-yaml" "$target"
  assert_failure && assert_error_contains "does not have extended attributes"
}

test_writes_yaml_with_values() {
  stub_dir=$(make_stub_dir)
  cat >"$stub_dir/xattr" <<'STUB'
#!/bin/sh
if [ "$1" = "-p" ]; then
  # print value
  printf '%s' "value-for-$2"
  exit 0
fi
printf '%s\n' 'user.alpha' 'user.beta'
STUB
  cat >"$stub_dir/setfattr" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"${WIZARDRY_TMPDIR}/enchantment.calls"
exit 0
STUB
  chmod +x "$stub_dir/xattr" "$stub_dir/setfattr"

  target="$WIZARDRY_TMPDIR/yaml-scroll"
  printf 'content\n' >"$target"

  PATH="$stub_dir:$PATH" run_spell "spells/enchant/enchantment-to-yaml" "$target"
  assert_success
  # YAML header should be prepended with values
  header=$(head -n 4 "$target")
  printf '%s\n' "$header" | grep '^---$' >/dev/null || { TEST_FAILURE_REASON="missing YAML start"; return 1; }
  printf '%s\n' "$header" | grep '^user.alpha: value-for-user.alpha$' >/dev/null || { TEST_FAILURE_REASON="missing alpha"; return 1; }
  printf '%s\n' "$header" | grep '^user.beta: value-for-user.beta$' >/dev/null || { TEST_FAILURE_REASON="missing beta"; return 1; }
  printf '%s\n' "$header" | tail -n 1 | grep '^---$' >/dev/null || { TEST_FAILURE_REASON="missing YAML end"; return 1; }
  # Attributes cleared via helper
  calls=$(cat "$WIZARDRY_TMPDIR/enchantment.calls")
  expected="-x user.alpha $target
-x user.beta $target"
  [ "$calls" = "$expected" ] || { TEST_FAILURE_REASON="unexpected helper calls: $calls"; return 1; }
}

test_reports_missing_helpers() {
  stub_dir=$(make_stub_dir)
  cat >"$stub_dir/getfattr" <<'STUB'
#!/bin/sh
printf '%s\n' 'user.alpha'
STUB
  chmod +x "$stub_dir/getfattr"

  target="$WIZARDRY_TMPDIR/yaml-missing"
  printf 'content\n' >"$target"

  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/fs:$stub_dir:/usr/bin:/bin" run_spell "spells/enchant/enchantment-to-yaml" "$target"
  assert_failure && assert_error_contains "requires one of attr, xattr, or setfattr"
}

run_test_case "enchantment-to-yaml prints usage" test_help
run_test_case "enchantment-to-yaml validates arguments" test_argument_validation
run_test_case "enchantment-to-yaml fails for missing files" test_missing_file
run_test_case "enchantment-to-yaml errors when no attributes exist" test_requires_attributes
run_test_case "enchantment-to-yaml writes YAML and clears attributes" test_writes_yaml_with_values
run_test_case "enchantment-to-yaml reports missing helpers" test_reports_missing_helpers
finish_tests
