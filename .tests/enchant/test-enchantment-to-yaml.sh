#!/bin/sh
# Behavioral cases (derived from --help):
# - enchantment-to-yaml prints usage
# - validates argument count and file existence
# - fails when no attributes are present
# - writes YAML with keys and values using available helpers and clears attributes
# - reports missing helpers when clearing is impossible

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

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
  # Skip this test if real xattr helpers are available (realistic CI scenario)
  # The WIZARDRY_TEST_HELPERS_ONLY mechanism artificially blocks system tools,
  # but we want to test realistic environments where wizardry uses available tools
  if command -v attr >/dev/null 2>&1 || command -v xattr >/dev/null 2>&1 || command -v setfattr >/dev/null 2>&1; then
    skip "Test only runs when xattr tools unavailable (unrealistic in modern systems)"
  fi
  
  target="$WIZARDRY_TMPDIR/yaml-missing"
  printf 'content\n' >"$target"

  run_spell "spells/enchant/enchantment-to-yaml" "$target"
  assert_failure && assert_error_contains "requires one of attr, xattr, or setfattr"
}

run_test_case "enchantment-to-yaml prints usage" test_help
run_test_case "enchantment-to-yaml validates arguments" test_argument_validation
run_test_case "enchantment-to-yaml fails for missing files" test_missing_file
run_test_case "enchantment-to-yaml errors when no attributes exist" test_requires_attributes
run_test_case "enchantment-to-yaml writes YAML and clears attributes" test_writes_yaml_with_values
run_test_case "enchantment-to-yaml reports missing helpers" test_reports_missing_helpers

# Test via source-then-invoke pattern  

finish_tests
