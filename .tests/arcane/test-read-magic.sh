#!/bin/sh
# Behavioral cases (derived from --help):
# - read-magic prints usage

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


MKTEMP_BIN=$(command -v mktemp)
TOUCH_BIN=$(command -v touch)

reset_path() {
  PATH="$ROOT_DIR/spells:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/menu:$ROOT_DIR/spells/menu/system:$ROOT_DIR/spells/menu/install/core:/usr/bin:/bin"
  export PATH
}

create_stub_dir() {
  dir=$($MKTEMP_BIN -d "$WIZARDRY_TMPDIR/stub.XXXXXX") || exit 1
  printf '%s\n' "$dir"
}

create_temp_file() {
  file=$($MKTEMP_BIN "$WIZARDRY_TMPDIR/read-magic.XXXXXX") || exit 1
  : >"$file"
  printf '%s\n' "$file"
}

test_help() {
  reset_path
  run_spell "spells/arcane/read-magic" --help
  assert_success && assert_output_contains "Usage: read-magic"
}

test_requires_argument() {
  reset_path
  run_spell "spells/arcane/read-magic"
  assert_failure && assert_output_contains "one or two parameters expected"
}

test_rejects_extra_argument() {
  reset_path
  run_spell "spells/arcane/read-magic" one two three
  assert_failure && assert_output_contains "one or two parameters expected"
}

test_missing_file() {
  reset_path
  run_spell "spells/arcane/read-magic" "$WIZARDRY_TMPDIR/does-not-exist"
  assert_failure && assert_output_contains "file does not exist"
}

test_lists_attributes_via_attr() {
  reset_path
  target=$(create_temp_file)
  stub_dir=$(create_stub_dir)
  cat >"$stub_dir/attr" <<'STUB'
#!/bin/sh
case "$1" in
  -l)
    printf '%s\n' "user.alpha" "user.beta"
    ;;
  -g)
    case "$2" in
      user.alpha)
        printf 'Attribute "user.alpha" had a 11 byte value for %s:\nalpha-value\n' "$3"
        ;;
      user.beta)
        printf 'Attribute "user.beta" had a 10 byte value for %s:\nbeta-value\n' "$3"
        ;;
      *)
        exit 1
        ;;
    esac
    ;;
  *)
    exit 1
    ;;
esac
STUB
  chmod +x "$stub_dir/attr"
  PATH="$stub_dir:$PATH" run_spell "spells/arcane/read-magic" "$target"
  assert_success
  assert_output_contains "user.alpha: alpha-value"
  assert_output_contains "user.beta: beta-value"
}

test_reads_specific_attribute_via_attr() {
  reset_path
  target=$(create_temp_file)
  stub_dir=$(create_stub_dir)
  cat >"$stub_dir/attr" <<'STUB'
#!/bin/sh
if [ "$1" = "-g" ] && [ "$2" = "user.charm" ]; then
  printf 'Attribute "user.charm" had a 7 byte value for %s:\nsparkle\n' "$3"
  exit 0
fi
exit 1
STUB
  chmod +x "$stub_dir/attr"
  PATH="$stub_dir:$PATH" run_spell "spells/arcane/read-magic" "$target" user.charm
  assert_success && assert_output_contains "sparkle"
}

test_lists_attributes_via_xattr_listing() {
  reset_path
  target=$(create_temp_file)
  stub_dir=$(create_stub_dir)
  cat >"$stub_dir/xattr" <<'STUB'
#!/bin/sh
case "$1" in
  -p)
    case "$2" in
      user.sky)
        printf 'azure'
        ;;
      *)
        exit 1
        ;;
    esac
    ;;
  *)
    printf '%s\n' 'user.sky' 'user.horizon'
    ;;
esac
STUB
  chmod +x "$stub_dir/xattr"

  PATH="$stub_dir:$PATH" run_spell "spells/arcane/read-magic" "$target"
  assert_success
  assert_output_contains "user.sky: azure"
  assert_output_contains "user.horizon:"
}

test_reads_attribute_via_xattr_when_attr_missing() {
  reset_path
  target=$(create_temp_file)
  stub_dir=$(create_stub_dir)
  cat >"$stub_dir/xattr" <<'STUB'
#!/bin/sh
if [ "$1" = "-p" ] && [ "$2" = "user.charm" ]; then
  printf 'xattr-magic\n'
  exit 0
fi
exit 1
STUB
  chmod +x "$stub_dir/xattr"
  PATH="$stub_dir:$PATH" run_spell "spells/arcane/read-magic" "$target" user.charm
  assert_success && assert_output_contains "xattr-magic"
}

test_lists_attributes_via_getfattr_when_others_missing() {
  reset_path
  target=$(create_temp_file)
  stub_dir=$(create_stub_dir)
  cat >"$stub_dir/getfattr" <<'STUB'
#!/bin/sh
case "$1" in
  -d)
    printf '# file: %s\n' "$2"
    printf '%s\n' 'user.first="one"' 'user.second="two"'
    ;;
  -n)
    key=$2
    case "$key" in
      user.first)
        printf 'one'
        ;;
      user.second)
        printf 'two'
        ;;
      *)
        exit 1
        ;;
    esac
    ;;
esac
STUB
  chmod +x "$stub_dir/getfattr"

  PATH="$stub_dir:$PATH" run_spell "spells/arcane/read-magic" "$target"
  assert_success
  assert_output_contains "user.first: one"
  assert_output_contains "user.second: two"
}

test_reads_attribute_via_getfattr_when_others_missing() {
  reset_path
  target=$(create_temp_file)
  stub_dir=$(create_stub_dir)
  cat >"$stub_dir/getfattr" <<'STUB'
#!/bin/sh
while [ "$#" -gt 0 ]; do
  case "$1" in
    -n)
      shift
      key=$1
      ;;
    --only-values)
      ;;
  esac
  shift
done
if [ "$key" = "user.charisma" ]; then
  printf 'shiny\n'
  exit 0
fi
exit 1
STUB
  chmod +x "$stub_dir/getfattr"
  PATH="$stub_dir:$PATH" run_spell "spells/arcane/read-magic" "$target" user.charisma
  assert_success && assert_output_contains "shiny"
}

test_reports_missing_attribute() {
  reset_path
  target=$(create_temp_file)
  stub_dir=$(create_stub_dir)
  cat >"$stub_dir/attr" <<'STUB'
#!/bin/sh
exit 1
STUB
  chmod +x "$stub_dir/attr"
  PATH="$stub_dir:$PATH" run_spell "spells/arcane/read-magic" "$target" user.none
  assert_failure && assert_output_contains "attribute does not exist"
}

test_handles_missing_helpers() {
  reset_path
  target=$(create_temp_file)
  stub_dir=$(create_stub_dir)
  PATH="$stub_dir:$PATH"
  export PATH
  run_spell "spells/arcane/read-magic" "$target"
  assert_success && assert_output_contains "No enchanted attributes found"
}

run_test_case "read-magic prints usage" test_help
run_test_case "read-magic requires an argument" test_requires_argument
run_test_case "read-magic rejects extra arguments" test_rejects_extra_argument
run_test_case "read-magic fails on missing file" test_missing_file
run_test_case "read-magic lists attributes via attr" test_lists_attributes_via_attr
run_test_case "read-magic reads specific attribute via attr" test_reads_specific_attribute_via_attr
run_test_case "read-magic lists attributes via xattr when attr is missing" test_lists_attributes_via_xattr_listing
run_test_case "read-magic uses xattr when attr is missing" test_reads_attribute_via_xattr_when_attr_missing
run_test_case "read-magic lists attributes via getfattr when other helpers are missing" test_lists_attributes_via_getfattr_when_others_missing
run_test_case "read-magic uses getfattr as a final fallback" test_reads_attribute_via_getfattr_when_others_missing
run_test_case "read-magic reports missing attribute" test_reports_missing_attribute
run_test_case "read-magic reports no attributes without helpers" test_handles_missing_helpers

finish_tests
