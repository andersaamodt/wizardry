#!/bin/sh
# Behavioral cases (derived from --help):
# - enchant prints usage
# - enforce argument count and file existence
# - honor helper preference and fall back between helpers
# - reject unknown helpers and report when no helpers are available

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


test_help() {
  run_spell "spells/enchant/enchant" --help
  assert_success && assert_output_contains "Usage: enchant"
}

test_requires_arguments() {
  # Test with no arguments
  run_spell "spells/enchant/enchant"
  assert_failure && assert_error_contains "At least one argument is required"
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
finish_tests
