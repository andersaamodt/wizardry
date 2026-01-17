#!/bin/sh
# Behavioral cases (derived from --help):
# - enchant prints usage
# - enforce argument count and file existence
# - honor helper preference and fall back between helpers
# - reject unknown helpers and report when no helpers are available

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/enchant/enchant" --help
  assert_success && assert_output_contains "Usage: enchant"
}

test_requires_arguments() {
  skip-if-compiled || return $?
  # Test with no arguments
  run_spell "spells/enchant/enchant"
  assert_failure && assert_error_contains "at least one argument required"
}

test_requires_attr_value_format_single_arg() {
  # Test single arg without = format
  run_spell "spells/enchant/enchant" "noequals"
  assert_failure && assert_error_contains "attribute=value format"
}

test_requires_valid_format_two_args() {
  # Test two args without either being attribute=value format
  run_spell "spells/enchant/enchant" one two
  assert_failure && assert_error_contains "'attribute=value' format"
}

test_rejects_empty_attr_or_value() {
  # Test that =value (empty attr) is rejected
  run_spell "spells/enchant/enchant" "=onlyvalue"
  assert_failure && assert_error_contains "attribute=value format"
}

test_rejects_attr_without_value() {
  # Test that attr= (empty value) is rejected
  run_spell "spells/enchant/enchant" "onlyattr="
  assert_failure && assert_error_contains "attribute=value format"
}

test_missing_file() {
  run_spell "spells/enchant/enchant" "$WIZARDRY_TMPDIR/missing" key value
  assert_failure && assert_error_contains "file does not exist"
}

# Tests for new 2-arg format with order detection
test_two_args_file_first() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  target="$tmpdir/target"
  mkdir -p "$stub_dir"
  : >"$target"
  cat >"$stub_dir/attribute-set" <<STUB
#!/bin/sh
# Mock attribute-set imp
printf '%s %s %s\n' "\$1" "\$2" "\$3" >"${WIZARDRY_TMPDIR:?}/enchant.called"
exit 0
STUB
  chmod +x "$stub_dir/attribute-set"
  PATH="$stub_dir:$PATH" run_spell "spells/enchant/enchant" "$target" "user.name=test_value"
  assert_success || return 1
  called=$(cat "$WIZARDRY_TMPDIR/enchant.called")
  assert_output_contains "enchanted with the attribute 'user.name'" || return 1
  [ "$called" = "user.name test_value $target" ] || { TEST_FAILURE_REASON="unexpected attribute-set call: $called"; return 1; }
}

test_two_args_attr_first() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  target="$tmpdir/target"
  mkdir -p "$stub_dir"
  : >"$target"
  cat >"$stub_dir/attribute-set" <<STUB
#!/bin/sh
# Mock attribute-set imp
printf '%s %s %s\n' "\$1" "\$2" "\$3" >"${WIZARDRY_TMPDIR:?}/enchant.called"
exit 0
STUB
  chmod +x "$stub_dir/attribute-set"
  PATH="$stub_dir:$PATH" run_spell "spells/enchant/enchant" "user.other=another_val" "$target"
  assert_success || return 1
  called=$(cat "$WIZARDRY_TMPDIR/enchant.called")
  assert_output_contains "enchanted with the attribute 'user.other'" || return 1
  [ "$called" = "user.other another_val $target" ] || { TEST_FAILURE_REASON="unexpected attribute-set call: $called"; return 1; }
}

test_legacy_three_arg_format() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  target="$tmpdir/target"
  mkdir -p "$stub_dir"
  : >"$target"
  cat >"$stub_dir/attribute-set" <<STUB
#!/bin/sh
# Mock attribute-set imp
printf '%s %s %s\n' "\$1" "\$2" "\$3" >"${WIZARDRY_TMPDIR:?}/enchant.called"
exit 0
STUB
  chmod +x "$stub_dir/attribute-set"
  PATH="$stub_dir:$PATH" run_spell "spells/enchant/enchant" "$target" charm sparkle
  assert_success || return 1
  called=$(cat "$WIZARDRY_TMPDIR/enchant.called")
  assert_output_contains "enchanted with the attribute 'user.charm'" || return 1
  [ "$called" = "user.charm sparkle $target" ] || { TEST_FAILURE_REASON="unexpected attribute-set call: $called"; return 1; }
}

test_reports_missing_helpers() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  cat >"$stub_dir/attribute-set" <<'STUB'
#!/bin/sh
# Mock attribute-set that always fails
exit 1
STUB
  chmod +x "$stub_dir/attribute-set"
  target="$tmpdir/target"
  : >"$target"
  PATH="$stub_dir:$PATH" run_spell "spells/enchant/enchant" "$target" user.key note
  assert_failure && assert_error_contains "requires the 'attr', 'xattr', or 'setfattr'"
}

run_test_case "enchant prints usage" test_help
run_test_case "enchant enforces argument count" test_requires_arguments
run_test_case "enchant requires attr=value format with single arg" test_requires_attr_value_format_single_arg
run_test_case "enchant requires valid format with two args" test_requires_valid_format_two_args
run_test_case "enchant rejects empty attr" test_rejects_empty_attr_or_value
run_test_case "enchant rejects attr without value" test_rejects_attr_without_value
run_test_case "enchant fails for missing files" test_missing_file
run_test_case "enchant works with 2 args (file first)" test_two_args_file_first
run_test_case "enchant works with 2 args (attr=value first)" test_two_args_attr_first
run_test_case "enchant works with legacy 3-arg format" test_legacy_three_arg_format
run_test_case "enchant reports missing helpers" test_reports_missing_helpers

finish_tests
