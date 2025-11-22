#!/bin/sh
# Behavioral cases (derived from --help):
# - enchant prints usage
# - enforce argument count and file existence
# - honor helper preference and fall back between helpers
# - reject unknown helpers and report when no helpers are available

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

test_help() {
  run_spell "spells/enchant" --help
  assert_success && assert_output_contains "Usage: enchant"
}

test_requires_arguments() {
  run_spell "spells/enchant" one two
  assert_failure && assert_error_contains "requires three or four arguments"
}

test_missing_file() {
  run_spell "spells/enchant" "$WIZARDRY_TMPDIR/missing" key value
  assert_failure && assert_error_contains "file does not exist"
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
  PATH="$stub_dir:$PATH" run_spell "spells/enchant" "$target" user.charm sparkle xattr
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
  PATH="$stub_dir:$PATH" run_spell "spells/enchant" "$target" user.aura glow attr
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

  PATH="$stub_dir:$PATH" run_spell "spells/enchant" "$target" user.pref other xattr
  assert_success
  called=$(cat "$WIZARDRY_TMPDIR/enchant.called")
  [ "$called" = "-n user.pref -v other $target" ] || { TEST_FAILURE_REASON="unexpected setfattr call: $called"; return 1; }
}

test_rejects_unknown_helper() {
  tmpdir=$(make_tempdir)
  target="$tmpdir/target"
  : >"$target"
  run_spell "spells/enchant" "$target" user.spell value wand
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
  PATH="$stub_dir:$PATH" run_spell "spells/enchant" "$target" user.key note
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

  PATH="$stub_dir:$PATH" run_spell "spells/enchant" "$target" user.fail value attr
  assert_failure
  assert_error_contains "Failed to set attribute using 'attr'"
  assert_error_contains "no permission"
}

run_test_case "enchant prints usage" test_help
run_test_case "enchant enforces argument count" test_requires_arguments
run_test_case "enchant fails for missing files" test_missing_file
run_test_case "enchant honors preferred helper" test_prefers_requested_helper
run_test_case "enchant falls back when preferred helper fails" test_falls_back_when_preference_missing
run_test_case "enchant falls back when preferred helper is missing" test_prefers_other_helpers_when_first_missing
run_test_case "enchant rejects unknown helper" test_rejects_unknown_helper
run_test_case "enchant reports missing helpers" test_reports_missing_helpers
run_test_case "enchant reports helper failures" test_reports_helper_failure
finish_tests
