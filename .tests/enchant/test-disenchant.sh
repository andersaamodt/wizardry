#!/bin/sh
# COMPILED_UNSUPPORTED: requires interactive ask-number for menu selection
# Behavioral cases (derived from --help):
# - disenchant prints usage
# - validates argument count and file existence
# - reports when no attributes exist
# - removes specific keys using available helpers and falls back when some helpers are missing
# - prompts through ask_number when multiple attributes exist, including selecting all

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/enchant/disenchant" --help
  _assert_success && _assert_output_contains "Usage: disenchant"
}

test_argument_validation() {
  _run_spell "spells/enchant/disenchant"
  _assert_failure && _assert_error_contains "Usage: disenchant"

  _run_spell "spells/enchant/disenchant" a b c
  _assert_failure && _assert_error_contains "Usage: disenchant"
}

test_missing_file() {
  _run_spell "spells/enchant/disenchant" "$WIZARDRY_TMPDIR/missing"
  _assert_failure && _assert_error_contains "does not exist"
}

test_no_attributes() {
  # Skip if no xattr commands available
  if ! command -v attr >/dev/null 2>&1 && ! command -v xattr >/dev/null 2>&1 && ! command -v getfattr >/dev/null 2>&1; then
    _test_skip "disenchant reports missing attributes" "requires attr, xattr, or getfattr"
    return 0
  fi
  
  tmpdir=$(_make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  cat >"$stub_dir/attr" <<'STUB'
#!/bin/sh
if [ "$1" = "-l" ]; then
  exit 0
fi
exit 1
STUB
  chmod +x "$stub_dir/attr"

  tmpfile="$tmpdir/blank"
  : >"$tmpfile"
  
  export PATH="$stub_dir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/menu:/bin:/usr/bin"
  _run_spell "spells/enchant/disenchant" "$tmpfile"
  
  _assert_failure && _assert_error_contains "no enchanted attributes"
}

test_removes_specific_key_with_attr() {
  # Skip if no xattr commands available
  if ! command -v attr >/dev/null 2>&1 && ! command -v xattr >/dev/null 2>&1 && ! command -v getfattr >/dev/null 2>&1; then
    _test_skip "disenchant removes a named key with attr" "requires attr, xattr, or getfattr"
    return 0
  fi
  
  tmpdir=$(_make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Use WIZARDRY_TMPDIR for output file so it's accessible in sandbox
  output_file="$WIZARDRY_TMPDIR/disenchant.call"
  rm -f "$output_file"
  
  cat >"$stub_dir/attr" <<EOF
#!/bin/sh
if [ "\$1" = "-r" ]; then
  printf '%s\n' "\$*" >"$output_file"
fi
exit 0
EOF
  chmod +x "$stub_dir/attr"

  target="$tmpdir/scroll"
  : >"$target"

  export PATH="$stub_dir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/menu:/bin:/usr/bin"
  _run_spell "spells/enchant/disenchant" "$target" user.note
  
  _assert_success && _assert_output_contains "Disenchanted user.note"
  
  called=$(cat "$output_file")
  [ "$called" = "-r user.note $target" ] || { TEST_FAILURE_REASON="unexpected attr call: $called"; return 1; }
}

test_falls_back_to_setfattr() {
  # Skip if no xattr commands available
  if ! command -v attr >/dev/null 2>&1 && ! command -v xattr >/dev/null 2>&1 && ! command -v getfattr >/dev/null 2>&1; then
    _test_skip "disenchant falls back to setfattr when attr missing" "requires attr, xattr, or getfattr"
    return 0
  fi
  
  tmpdir=$(_make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Use WIZARDRY_TMPDIR for output file so it's accessible in sandbox
  output_file="$WIZARDRY_TMPDIR/disenchant.call"
  rm -f "$output_file"
  
  cat >"$stub_dir/getfattr" <<'STUB'
#!/bin/sh
printf '%s\n' 'user.alt'
STUB
  cat >"$stub_dir/setfattr" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >"$output_file"
exit 0
EOF
  chmod +x "$stub_dir/getfattr" "$stub_dir/setfattr"

  target="$tmpdir/scroll-alt"
  : >"$target"

  export PATH="$stub_dir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/menu:/bin:/usr/bin"
  _run_spell "spells/enchant/disenchant" "$target"
  _assert_success
  called=$(cat "$output_file")
  [ "$called" = "-x user.alt $target" ] || { TEST_FAILURE_REASON="unexpected setfattr call: $called"; return 1; }
}

test_requires_ask_number_when_many() {
  # Skip if no xattr commands available
  if ! command -v attr >/dev/null 2>&1 && ! command -v xattr >/dev/null 2>&1 && ! command -v getfattr >/dev/null 2>&1; then
    _test_skip "disenchant requires ask_number for multiple attributes" "requires attr, xattr, or getfattr"
    return 0
  fi
  
  tmpdir=$(_make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  cat >"$stub_dir/xattr" <<'STUB'
#!/bin/sh
if [ "$1" = "-d" ]; then
  exit 0
fi
printf '%s\n' 'user.one' 'user.two'
STUB
  chmod +x "$stub_dir/xattr"

  target="$tmpdir/multi"
  : >"$target"
  
  export PATH="$stub_dir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/menu:/usr/bin:/bin"
  _run_spell "spells/enchant/disenchant" "$target"
  _assert_failure && _assert_error_contains "multiple attributes"
}

test_selects_specific_entry_with_ask_number() {
  # Skip if no xattr commands available
  if ! command -v attr >/dev/null 2>&1 && ! command -v xattr >/dev/null 2>&1 && ! command -v getfattr >/dev/null 2>&1; then
    _test_skip "disenchant selects a specific entry with ask_number" "requires attr, xattr, or getfattr"
    return 0
  fi
  
  tmpdir=$(_make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Use WIZARDRY_TMPDIR for output file so it's accessible in sandbox
  output_file="$WIZARDRY_TMPDIR/disenchant.call"
  rm -f "$output_file"
  
  cat >"$stub_dir/xattr" <<EOF
#!/bin/sh
if [ "\$1" = "-d" ]; then
  printf '%s\n' "\$*" >"$output_file"
  exit 0
fi
printf '%s\n' 'user.one' 'user.two'
EOF
  cat >"$stub_dir/ask-number" <<'STUB'
#!/bin/sh
printf '%s\n' 2
STUB
  chmod +x "$stub_dir/xattr" "$stub_dir/ask-number"

  target="$tmpdir/multi-choice"
  : >"$target"
  
  export PATH="$stub_dir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/menu:/bin:/usr/bin"
  _run_spell "spells/enchant/disenchant" "$target"
  _assert_success && _assert_output_contains "user.two"
  called=$(cat "$output_file")
  [ "$called" = "-d user.two $target" ] || { TEST_FAILURE_REASON="unexpected xattr call: $called"; return 1; }
}

test_selects_all_with_menu_choice() {
  # Skip if no xattr commands available
  if ! command -v attr >/dev/null 2>&1 && ! command -v xattr >/dev/null 2>&1 && ! command -v getfattr >/dev/null 2>&1; then
    _test_skip "disenchant can remove all attributes" "requires attr, xattr, or getfattr"
    return 0
  fi
  
  tmpdir=$(_make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Use WIZARDRY_TMPDIR for output file so it's accessible in sandbox
  output_file="$WIZARDRY_TMPDIR/disenchant.calls"
  rm -f "$output_file"
  
  cat >"$stub_dir/attr" <<EOF
#!/bin/sh
case "\$1" in
  -l)
    printf '%s\n' 'Attribute "user.alpha" has a value: 1' 'Attribute "user.beta" has a value: 2'
    ;;
  -r)
    printf '%s\n' "\$*" >>"$output_file"
    ;;
esac
exit 0
EOF
  cat >"$stub_dir/ask-number" <<'STUB'
#!/bin/sh
printf '%s\n' 3
STUB
  chmod +x "$stub_dir/attr" "$stub_dir/ask-number"

  target="$tmpdir/multi-all"
  : >"$target"
  
  export PATH="$stub_dir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/menu:/bin:/usr/bin"
  _run_spell "spells/enchant/disenchant" "$target"
  _assert_success && _assert_output_contains "Disenchant all"
  calls=$(cat "$output_file")
  expected="-r user.alpha $target
-r user.beta $target"
  [ "$calls" = "$expected" ] || { TEST_FAILURE_REASON="unexpected attr calls: $calls"; return 1; }
}

_run_test_case "disenchant prints usage" test_help
_run_test_case "disenchant validates arguments" test_argument_validation
_run_test_case "disenchant fails for missing files" test_missing_file
_run_test_case "disenchant reports missing attributes" test_no_attributes
_run_test_case "disenchant removes a named key with attr" test_removes_specific_key_with_attr
_run_test_case "disenchant falls back to setfattr when attr missing" test_falls_back_to_setfattr
_run_test_case "disenchant requires ask_number for multiple attributes" test_requires_ask_number_when_many
_run_test_case "disenchant selects a specific entry with ask_number" test_selects_specific_entry_with_ask_number
_run_test_case "disenchant can remove all attributes" test_selects_all_with_menu_choice
_finish_tests
