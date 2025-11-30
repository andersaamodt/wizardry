#!/bin/sh
# Behavioral cases (derived from --help):
# - yaml-to-enchantment prints usage
# - validates argument count and file existence
# - fails when YAML header is missing
# - restores attributes using available helpers and trims the header
# - reports missing helpers
# - stops on attribute write failures

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

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
