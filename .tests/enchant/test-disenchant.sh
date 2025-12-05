#!/bin/sh
# Behavioral cases (derived from --help):
# - disenchant prints usage
# - validates argument count and file existence
# - reports when no attributes exist
# - removes specific keys using available helpers and falls back when some helpers are missing
# - prompts through ask_number when multiple attributes exist, including selecting all

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
  run_spell "spells/enchant/disenchant" --help
  assert_success && assert_output_contains "Usage: disenchant"
}

test_argument_validation() {
  run_spell "spells/enchant/disenchant"
  assert_failure && assert_error_contains "requires one or two arguments"

  run_spell "spells/enchant/disenchant" a b c
  assert_failure && assert_error_contains "requires one or two arguments"
}

test_missing_file() {
  run_spell "spells/enchant/disenchant" "$WIZARDRY_TMPDIR/missing"
  assert_failure && assert_error_contains "does not exist"
}

test_no_attributes() {
  stub_dir=$(make_stub_dir)
  cat >"$stub_dir/attr" <<'STUB'
#!/bin/sh
if [ "$1" = "-l" ]; then
  exit 0
fi
STUB
  chmod +x "$stub_dir/attr"

  tmpfile="$WIZARDRY_TMPDIR/blank"
  : >"$tmpfile"
  PATH="$stub_dir:$PATH" run_spell "spells/enchant/disenchant" "$tmpfile"
  assert_failure && assert_error_contains "No enchanted attributes"
}

test_removes_specific_key_with_attr() {
  stub_dir=$(make_stub_dir)
  cat >"$stub_dir/attr" <<'STUB'
#!/bin/sh
if [ "$1" = "-r" ]; then
  printf '%s\n' "$*" >"${WIZARDRY_TMPDIR}/disenchant.call"
fi
exit 0
STUB
  chmod +x "$stub_dir/attr"

  target="$WIZARDRY_TMPDIR/scroll"
  : >"$target"

  PATH="$stub_dir:$PATH" run_spell "spells/enchant/disenchant" "$target" user.note
  assert_success && assert_output_contains "Disenchanted user.note"
  called=$(cat "$WIZARDRY_TMPDIR/disenchant.call")
  [ "$called" = "-r user.note $target" ] || { TEST_FAILURE_REASON="unexpected attr call: $called"; return 1; }
}

test_falls_back_to_setfattr() {
  stub_dir=$(make_stub_dir)
  cat >"$stub_dir/getfattr" <<'STUB'
#!/bin/sh
printf '%s\n' 'user.alt'
STUB
  cat >"$stub_dir/setfattr" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >"${WIZARDRY_TMPDIR}/disenchant.call"
exit 0
STUB
  chmod +x "$stub_dir/getfattr" "$stub_dir/setfattr"

  target="$WIZARDRY_TMPDIR/scroll-alt"
  : >"$target"

  PATH="$stub_dir:$PATH" run_spell "spells/enchant/disenchant" "$target"
  assert_success
  called=$(cat "$WIZARDRY_TMPDIR/disenchant.call")
  [ "$called" = "-x user.alt $target" ] || { TEST_FAILURE_REASON="unexpected setfattr call: $called"; return 1; }
}

test_requires_ask_number_when_many() {
  stub_dir=$(make_stub_dir)
  cat >"$stub_dir/xattr" <<'STUB'
#!/bin/sh
if [ "$1" = "-d" ]; then
  exit 0
fi
printf '%s\n' 'user.one' 'user.two'
STUB
  chmod +x "$stub_dir/xattr"

  target="$WIZARDRY_TMPDIR/multi"
  : >"$target"
  PATH="$stub_dir:/usr/bin:/bin" run_spell "spells/enchant/disenchant" "$target"
  assert_failure && assert_error_contains "multiple attributes"
}

test_selects_specific_entry_with_ask_number() {
  stub_dir=$(make_stub_dir)
  cat >"$stub_dir/xattr" <<'STUB'
#!/bin/sh
if [ "$1" = "-d" ]; then
  printf '%s\n' "$*" >"${WIZARDRY_TMPDIR}/disenchant.call"
  exit 0
fi
printf '%s\n' 'user.one' 'user.two'
STUB
  cat >"$stub_dir/ask-number" <<'STUB'
#!/bin/sh
printf '%s\n' 2
STUB
  chmod +x "$stub_dir/xattr" "$stub_dir/ask-number"

  target="$WIZARDRY_TMPDIR/multi-choice"
  : >"$target"
  PATH="$stub_dir:$PATH" run_spell "spells/enchant/disenchant" "$target"
  assert_success && assert_output_contains "user.two"
  called=$(cat "$WIZARDRY_TMPDIR/disenchant.call")
  [ "$called" = "-d user.two $target" ] || { TEST_FAILURE_REASON="unexpected xattr call: $called"; return 1; }
}

test_selects_all_with_menu_choice() {
  stub_dir=$(make_stub_dir)
  cat >"$stub_dir/attr" <<'STUB'
#!/bin/sh
case "$1" in
  -l)
    printf '%s\n' 'Attribute "user.alpha" has a value: 1' 'Attribute "user.beta" has a value: 2'
    ;;
  -r)
    printf '%s\n' "$*" >>"${WIZARDRY_TMPDIR}/disenchant.calls"
    ;;
esac
exit 0
STUB
  cat >"$stub_dir/ask-number" <<'STUB'
#!/bin/sh
printf '%s\n' 3
STUB
  chmod +x "$stub_dir/attr" "$stub_dir/ask-number"

  target="$WIZARDRY_TMPDIR/multi-all"
  : >"$target"
  PATH="$stub_dir:$PATH" run_spell "spells/enchant/disenchant" "$target"
  assert_success && assert_output_contains "Disenchanted all"
  calls=$(cat "$WIZARDRY_TMPDIR/disenchant.calls")
  expected="-r user.alpha $target
-r user.beta $target"
  [ "$calls" = "$expected" ] || { TEST_FAILURE_REASON="unexpected attr calls: $calls"; return 1; }
}

run_test_case "disenchant prints usage" test_help
run_test_case "disenchant validates arguments" test_argument_validation
run_test_case "disenchant fails for missing files" test_missing_file
run_test_case "disenchant reports missing attributes" test_no_attributes
run_test_case "disenchant removes a named key with attr" test_removes_specific_key_with_attr
run_test_case "disenchant falls back to setfattr when attr missing" test_falls_back_to_setfattr
run_test_case "disenchant requires ask_number for multiple attributes" test_requires_ask_number_when_many
run_test_case "disenchant selects a specific entry with ask_number" test_selects_specific_entry_with_ask_number
run_test_case "disenchant can remove all attributes" test_selects_all_with_menu_choice
finish_tests
