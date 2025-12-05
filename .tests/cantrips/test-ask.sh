#!/bin/sh
# Behavioral cases (derived from --help):
# - ask relays prompts to ask_text
# - ask passes arguments to ask_text
# - ask uses default when provided
# - ask fails without default when no input available

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


ask_relays_to_ask_text() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'guildmaster\\n' | \"$ROOT_DIR/spells/cantrips/ask\" 'Handle?'"
  assert_success && assert_output_contains "guildmaster"
}

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/cantrips/ask" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/cantrips/ask" ]
}

# Test that ask passes default argument to ask_text
test_ask_passes_default() {
  run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask" "Color?" "green"
  assert_success && assert_output_contains "green"
}

# Test ask uses default on empty input
test_ask_default_on_empty() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '\\n' | \"$ROOT_DIR/spells/cantrips/ask\" 'Name?' 'anonymous'"
  assert_success && assert_output_contains "anonymous"
}

# Test ask fails without default and no input
test_ask_fails_without_default() {
  run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask" "Required?"
  assert_failure && assert_error_contains "No interactive input available."
}

# Test ask returns user input when provided
test_ask_returns_user_input() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'myinput\\n' | \"$ROOT_DIR/spells/cantrips/ask\" 'Enter:'"
  assert_success && assert_output_contains "myinput"
}

# Test ask preserves input with default ignored
test_ask_user_overrides_default() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'override\\n' | \"$ROOT_DIR/spells/cantrips/ask\" 'Name?' 'default'"
  assert_success && assert_output_contains "override"
}

# Test --help - ask shim does not directly handle help, it delegates to ask_text
# ask_text reads it as a question argument, which is the intended simple shim behavior
test_ask_help_behavior() {
  # ask now shows help when --help is passed
  run_cmd "$ROOT_DIR/spells/cantrips/ask" "--help"
  assert_success && assert_output_contains "Usage:"
}

run_test_case "ask relays prompts to ask_text" ask_relays_to_ask_text
run_test_case "cantrips/ask is executable" spell_is_executable
run_test_case "cantrips/ask has content" spell_has_content
run_test_case "ask passes default to ask_text" test_ask_passes_default
run_test_case "ask uses default on empty input" test_ask_default_on_empty
run_test_case "ask fails without default and no input" test_ask_fails_without_default
run_test_case "ask returns user input" test_ask_returns_user_input
run_test_case "ask user input overrides default" test_ask_user_overrides_default
run_test_case "ask --help behavior (delegates to ask_text)" test_ask_help_behavior
finish_tests
