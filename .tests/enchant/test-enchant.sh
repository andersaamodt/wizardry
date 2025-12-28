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
  cat >"$stub_dir/xattr" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >"${WIZARDRY_TMPDIR:?}/enchant.called"
exit 0
STUB
  chmod +x "$stub_dir/xattr"
  PATH="$stub_dir:$PATH" run_spell "spells/enchant/enchant" "$target" "user.name=test_value"
  assert_success
  called=$(cat "$WIZARDRY_TMPDIR/enchant.called")
  assert_output_contains "enchanted with the attribute 'user.name'"
  [ "$called" = "-w user.name test_value $target" ] || { TEST_FAILURE_REASON="unexpected xattr call: $called"; return 1; }
}

test_two_args_attr_first() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  target="$tmpdir/target"
  mkdir -p "$stub_dir"
  : >"$target"
  cat >"$stub_dir/xattr" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >"${WIZARDRY_TMPDIR:?}/enchant.called"
exit 0
STUB
  chmod +x "$stub_dir/xattr"
  PATH="$stub_dir:$PATH" run_spell "spells/enchant/enchant" "user.other=another_val" "$target"
  assert_success
  called=$(cat "$WIZARDRY_TMPDIR/enchant.called")
  assert_output_contains "enchanted with the attribute 'user.other'"
  [ "$called" = "-w user.other another_val $target" ] || { TEST_FAILURE_REASON="unexpected xattr call: $called"; return 1; }
}

test_prefers_requested_helper() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  target="$tmpdir/target"
  mkdir -p "$stub_dir"
  : >"$target"
  cat >"$stub_dir/xattr" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >"${WIZARDRY_TMPDIR:?}/enchant.called"
exit 0
STUB
  chmod +x "$stub_dir/xattr"
  PATH="$stub_dir:$PATH" run_spell "spells/enchant/enchant" "$target" user.charm sparkle xattr
  assert_success
  called=$(cat "$WIZARDRY_TMPDIR/enchant.called")
  assert_output_contains "enchanted with the attribute 'user.charm'"
  [ "$called" = "-w user.charm sparkle $target" ] || { TEST_FAILURE_REASON="unexpected xattr call: $called"; return 1; }
}

test_falls_back_when_preference_missing() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  target="$tmpdir/target"
  mkdir -p "$stub_dir"
  : >"$target"
  cat >"$stub_dir/attr" <<'STUB'
#!/bin/sh
exit 1
STUB
  cat >"$stub_dir/setfattr" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >"${WIZARDRY_TMPDIR:?}/enchant.called"
exit 0
STUB
  chmod +x "$stub_dir/attr" "$stub_dir/setfattr"
  PATH="$stub_dir:$PATH" run_spell "spells/enchant/enchant" "$target" user.aura glow attr
  assert_success
  called=$(cat "$WIZARDRY_TMPDIR/enchant.called")
  [ "$called" = "-n user.aura -v glow $target" ] || { TEST_FAILURE_REASON="unexpected setfattr call: $called"; return 1; }
}

test_prefers_other_helpers_when_first_missing() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  target="$tmpdir/target"
  mkdir -p "$stub_dir"
  : >"$target"

  cat >"$stub_dir/setfattr" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >"${WIZARDRY_TMPDIR:?}/enchant.called"
exit 0
STUB
  chmod +x "$stub_dir/setfattr"

  PATH="$stub_dir:$PATH" run_spell "spells/enchant/enchant" "$target" user.pref other xattr
  assert_success
  called=$(cat "$WIZARDRY_TMPDIR/enchant.called")
  [ "$called" = "-n user.pref -v other $target" ] || { TEST_FAILURE_REASON="unexpected setfattr call: $called"; return 1; }
}

test_rejects_unknown_helper() {
  tmpdir=$(make_tempdir)
  target="$tmpdir/target"
  : >"$target"
  run_spell "spells/enchant/enchant" "$target" user.spell value wand
  assert_failure && assert_error_contains "Unknown helper"
}

test_reports_missing_helpers() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  cat >"$stub_dir/attr" <<'STUB'
#!/bin/sh
exit 127
STUB
  cat >"$stub_dir/xattr" <<'STUB'
#!/bin/sh
exit 127
STUB
  cat >"$stub_dir/setfattr" <<'STUB'
#!/bin/sh
exit 127
STUB
  chmod +x "$stub_dir/attr" "$stub_dir/xattr" "$stub_dir/setfattr"
  target="$tmpdir/target"
  : >"$target"
  PATH="$stub_dir:$PATH" run_spell "spells/enchant/enchant" "$target" user.key note
  assert_failure && assert_error_contains "requires the 'attr', 'xattr', or 'setfattr'"
}

test_reports_helper_failure() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  cat >"$stub_dir/attr" <<'STUB'
#!/bin/sh
echo "no permission" >&2
exit 2
STUB
  chmod +x "$stub_dir/attr"

  target="$tmpdir/target"
  : >"$target"

  PATH="$stub_dir:$PATH" run_spell "spells/enchant/enchant" "$target" user.fail value attr
  assert_failure
  assert_error_contains "Failed to set attribute using 'attr'"
  assert_error_contains "no permission"
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
run_test_case "enchant honors preferred helper" test_prefers_requested_helper
run_test_case "enchant falls back when preferred helper fails" test_falls_back_when_preference_missing
run_test_case "enchant falls back when preferred helper is missing" test_prefers_other_helpers_when_first_missing
run_test_case "enchant rejects unknown helper" test_rejects_unknown_helper
run_test_case "enchant reports missing helpers" test_reports_missing_helpers
run_test_case "enchant reports helper failures" test_reports_helper_failure

# Test via source-then-invoke pattern  
