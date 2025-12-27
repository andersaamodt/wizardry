#!/bin/sh
# Behavioral cases (derived from --help):
# - read-magic prints usage

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

MKTEMP_BIN=$(command -v mktemp)
TOUCH_BIN=$(command -v touch)

reset_path() {
  PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/menu:$ROOT_DIR/spells/menu/system:$ROOT_DIR/spells/menu/install/core:/usr/bin:/bin"
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
  _run_spell "spells/arcane/read-magic" --help
  _assert_success && _assert_output_contains "Usage: read-magic"
}

test_requires_argument() {
  reset_path
  _run_spell "spells/arcane/read-magic"
  _assert_failure && _assert_error_contains "one or two parameters expected"
}

test_rejects_extra_argument() {
  reset_path
  _run_spell "spells/arcane/read-magic" one two three
  _assert_failure && _assert_error_contains "one or two parameters expected"
}

test_missing_file() {
  reset_path
  _run_spell "spells/arcane/read-magic" "$WIZARDRY_TMPDIR/does-not-exist"
  _assert_failure && _assert_error_contains "file does not exist"
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
  PATH="$stub_dir:$PATH" _run_spell "spells/arcane/read-magic" "$target"
  _assert_success
  _assert_output_contains "user.alpha: alpha-value"
  _assert_output_contains "user.beta: beta-value"
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
  PATH="$stub_dir:$PATH" _run_spell "spells/arcane/read-magic" "$target" user.charm
  _assert_success && _assert_output_contains "sparkle"
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

  PATH="$stub_dir:$PATH" _run_spell "spells/arcane/read-magic" "$target"
  _assert_success
  _assert_output_contains "user.sky: azure"
  _assert_output_contains "user.horizon:"
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
  PATH="$stub_dir:$PATH" _run_spell "spells/arcane/read-magic" "$target" user.charm
  _assert_success && _assert_output_contains "xattr-magic"
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

  PATH="$stub_dir:$PATH" _run_spell "spells/arcane/read-magic" "$target"
  _assert_success
  _assert_output_contains "user.first: one"
  _assert_output_contains "user.second: two"
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
  PATH="$stub_dir:$PATH" _run_spell "spells/arcane/read-magic" "$target" user.charisma
  _assert_success && _assert_output_contains "shiny"
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
  PATH="$stub_dir:$PATH" _run_spell "spells/arcane/read-magic" "$target" user.none
  _assert_failure && _assert_error_contains "attribute does not exist"
}

test_handles_missing_helpers() {
  reset_path
  target=$(create_temp_file)
  stub_dir=$(create_stub_dir)
  PATH="$stub_dir:$PATH"
  export PATH
  _run_spell "spells/arcane/read-magic" "$target"
  _assert_success && _assert_output_contains "No enchanted attributes found"
}

_run_test_case "read-magic prints usage" test_help
_run_test_case "read-magic requires an argument" test_requires_argument
_run_test_case "read-magic rejects extra arguments" test_rejects_extra_argument
_run_test_case "read-magic fails on missing file" test_missing_file
_run_test_case "read-magic lists attributes via attr" test_lists_attributes_via_attr
_run_test_case "read-magic reads specific attribute via attr" test_reads_specific_attribute_via_attr
_run_test_case "read-magic lists attributes via xattr when attr is missing" test_lists_attributes_via_xattr_listing
_run_test_case "read-magic uses xattr when attr is missing" test_reads_attribute_via_xattr_when_attr_missing
_run_test_case "read-magic lists attributes via getfattr when other helpers are missing" test_lists_attributes_via_getfattr_when_others_missing
_run_test_case "read-magic uses getfattr as a final fallback" test_reads_attribute_via_getfattr_when_others_missing
_run_test_case "read-magic reports missing attribute" test_reports_missing_attribute
_run_test_case "read-magic reports no attributes without helpers" test_handles_missing_helpers


# Test via source-then-invoke pattern  
