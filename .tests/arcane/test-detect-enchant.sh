#!/bin/sh
# Behavioral cases (derived from --help):
# - detect-enchant prints usage

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
  file=$($MKTEMP_BIN "$WIZARDRY_TMPDIR/detect-enchant.XXXXXX") || exit 1
  : >"$file"
  printf '%s\n' "$file"
}

test_help() {
  reset_path
  run_spell "spells/arcane/detect-enchant" --help
  assert_success && assert_output_contains "Usage: detect-enchant"
}

test_requires_argument() {
  reset_path
  run_spell "spells/arcane/detect-enchant"
  assert_failure && assert_error_contains "one or two parameters expected"
}

test_rejects_extra_argument() {
  reset_path
  run_spell "spells/arcane/detect-enchant" one two three
  assert_failure && assert_error_contains "one or two parameters expected"
}

test_missing_file() {
  reset_path
  run_spell "spells/arcane/detect-enchant" "$WIZARDRY_TMPDIR/does-not-exist"
  assert_failure && assert_error_contains "file does not exist"
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
  PATH="$stub_dir:$PATH" run_spell "spells/arcane/detect-enchant" "$target"
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
  PATH="$stub_dir:$PATH" run_spell "spells/arcane/detect-enchant" "$target" user.charm
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

  PATH="$stub_dir:$PATH" run_spell "spells/arcane/detect-enchant" "$target"
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
  PATH="$stub_dir:$PATH" run_spell "spells/arcane/detect-enchant" "$target" user.charm
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

  PATH="$stub_dir:$PATH" run_spell "spells/arcane/detect-enchant" "$target"
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
  PATH="$stub_dir:$PATH" run_spell "spells/arcane/detect-enchant" "$target" user.charisma
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
  PATH="$stub_dir:$PATH" run_spell "spells/arcane/detect-enchant" "$target" user.none
  assert_failure && assert_error_contains "attribute does not exist"
}

test_handles_missing_helpers() {
  reset_path
  target=$(create_temp_file)
  stub_dir=$(create_stub_dir)
  PATH="$stub_dir:$PATH"
  export PATH
  run_spell "spells/arcane/detect-enchant" "$target"
  assert_success && assert_output_contains "No enchanted attributes found"
}

run_test_case "detect-enchant prints usage" test_help
run_test_case "detect-enchant requires an argument" test_requires_argument
run_test_case "detect-enchant rejects extra arguments" test_rejects_extra_argument
run_test_case "detect-enchant fails on missing file" test_missing_file
run_test_case "detect-enchant lists attributes via attr" test_lists_attributes_via_attr
run_test_case "detect-enchant reads specific attribute via attr" test_reads_specific_attribute_via_attr
run_test_case "detect-enchant lists attributes via xattr when attr is missing" test_lists_attributes_via_xattr_listing
run_test_case "detect-enchant uses xattr when attr is missing" test_reads_attribute_via_xattr_when_attr_missing
run_test_case "detect-enchant lists attributes via getfattr when other helpers are missing" test_lists_attributes_via_getfattr_when_others_missing
run_test_case "detect-enchant uses getfattr as a final fallback" test_reads_attribute_via_getfattr_when_others_missing
run_test_case "detect-enchant reports missing attribute" test_reports_missing_attribute
run_test_case "detect-enchant reports no attributes without helpers" test_handles_missing_helpers


# Test via source-then-invoke pattern  
