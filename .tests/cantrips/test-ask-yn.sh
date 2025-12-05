#!/bin/sh
# Behavioral cases (derived from --help):
# - ask_yn defaults to yes on empty reply
# - ask_yn defaults to no on empty reply
# - ask_yn reprompts after invalid answer
# - ask_yn fails when input unavailable and no default
# - ask_yn rejects invalid default
# - ask_yn accepts various yes/no input formats
# - ask_yn shows usage on too few arguments
# - ask_yn shows usage on too many arguments
# - ask_yn uses default when no input available
# - ask_yn clears default after invalid input

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


test_ask_yn_accepts_default_yes() {
  run_cmd sh -c "printf '\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Continue?' yes"
  assert_success && assert_output_contains "yes"
}

test_ask_yn_accepts_default_no() {
  run_cmd sh -c "printf '\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Proceed?' no"
  assert_status 1 && assert_output_contains "no"
}

test_ask_yn_reprompts_after_invalid_answer() {
  run_cmd sh -c "printf 'maybe\\ny\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Ready?' yes"
  assert_success && assert_output_contains "yes" && assert_error_contains "Yes or no?"
}

test_ask_yn_fails_without_input_or_default() {
  run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask-yn" "Answer me"
  assert_failure && assert_error_contains "No interactive input available."
}

test_ask_yn_rejects_bad_default() {
  run_cmd "$ROOT_DIR/spells/cantrips/ask-yn" "Question" "maybe"
  assert_failure && assert_error_contains "default must be 'yes' or 'no'."
}

# Test various input formats for yes
test_ask_yn_accepts_lowercase_y() {
  run_cmd sh -c "printf 'y\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Confirm?'"
  assert_success && assert_output_contains "yes"
}

test_ask_yn_accepts_uppercase_Y() {
  run_cmd sh -c "printf 'Y\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Confirm?'"
  assert_success && assert_output_contains "yes"
}

test_ask_yn_accepts_word_yes() {
  run_cmd sh -c "printf 'yes\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Confirm?'"
  assert_success && assert_output_contains "yes"
}

test_ask_yn_accepts_uppercase_YES() {
  run_cmd sh -c "printf 'YES\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Confirm?'"
  assert_success && assert_output_contains "yes"
}

# Test various input formats for no
test_ask_yn_accepts_lowercase_n() {
  run_cmd sh -c "printf 'n\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Decline?'"
  assert_status 1 && assert_output_contains "no"
}

test_ask_yn_accepts_uppercase_N() {
  run_cmd sh -c "printf 'N\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Decline?'"
  assert_status 1 && assert_output_contains "no"
}

test_ask_yn_accepts_word_no() {
  run_cmd sh -c "printf 'no\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Decline?'"
  assert_status 1 && assert_output_contains "no"
}

test_ask_yn_accepts_uppercase_NO() {
  run_cmd sh -c "printf 'NO\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Decline?'"
  assert_status 1 && assert_output_contains "no"
}

# Test usage errors
test_ask_yn_shows_usage_no_args() {
  run_cmd "$ROOT_DIR/spells/cantrips/ask-yn"
  assert_failure && assert_error_contains "Usage:"
}

test_ask_yn_shows_usage_too_many_args() {
  run_cmd "$ROOT_DIR/spells/cantrips/ask-yn" "Question?" "yes" "extra"
  assert_failure && assert_error_contains "Usage:"
}

# Test default used when no interactive input available
test_ask_yn_uses_default_yes_when_no_input() {
  run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask-yn" "Proceed?" yes
  assert_success && assert_output_contains "yes"
}

test_ask_yn_uses_default_no_when_no_input() {
  run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask-yn" "Proceed?" no
  assert_status 1 && assert_output_contains "no"
}

# Test default hint display in prompt
test_ask_yn_shows_yes_hint_in_prompt() {
  run_cmd sh -c "printf 'y\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Continue?' yes"
  assert_success && assert_error_contains "[Y/n]"
}

test_ask_yn_shows_no_hint_in_prompt() {
  run_cmd sh -c "printf 'n\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Continue?' no"
  assert_failure && assert_error_contains "[y/N]"
}

test_ask_yn_shows_neutral_hint_no_default() {
  run_cmd sh -c "printf 'y\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Continue?'"
  assert_success && assert_error_contains "[y/n]"
}

# Test default alternate formats
test_ask_yn_accepts_uppercase_Y_default() {
  run_cmd sh -c "printf '\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Continue?' Y"
  assert_success && assert_output_contains "yes"
}

test_ask_yn_accepts_uppercase_N_default() {
  run_cmd sh -c "printf '\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Continue?' N"
  assert_status 1 && assert_output_contains "no"
}

test_ask_yn_accepts_uppercase_YES_default() {
  run_cmd sh -c "printf '\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Continue?' YES"
  assert_success && assert_output_contains "yes"
}

test_ask_yn_accepts_uppercase_NO_default() {
  run_cmd sh -c "printf '\\n' | \"$ROOT_DIR/spells/cantrips/ask-yn\" 'Continue?' NO"
  assert_status 1 && assert_output_contains "no"
}

run_test_case "ask_yn defaults to yes on empty reply" test_ask_yn_accepts_default_yes
run_test_case "ask_yn defaults to no on empty reply" test_ask_yn_accepts_default_no
run_test_case "ask_yn reprompts after invalid answer" test_ask_yn_reprompts_after_invalid_answer
run_test_case "ask_yn fails when input unavailable and no default" test_ask_yn_fails_without_input_or_default
run_test_case "ask_yn rejects invalid default" test_ask_yn_rejects_bad_default
run_test_case "ask_yn accepts lowercase y" test_ask_yn_accepts_lowercase_y
run_test_case "ask_yn accepts uppercase Y" test_ask_yn_accepts_uppercase_Y
run_test_case "ask_yn accepts word yes" test_ask_yn_accepts_word_yes
run_test_case "ask_yn accepts uppercase YES" test_ask_yn_accepts_uppercase_YES
run_test_case "ask_yn accepts lowercase n" test_ask_yn_accepts_lowercase_n
run_test_case "ask_yn accepts uppercase N" test_ask_yn_accepts_uppercase_N
run_test_case "ask_yn accepts word no" test_ask_yn_accepts_word_no
run_test_case "ask_yn accepts uppercase NO" test_ask_yn_accepts_uppercase_NO
run_test_case "ask_yn shows usage with no arguments" test_ask_yn_shows_usage_no_args
run_test_case "ask_yn shows usage with too many arguments" test_ask_yn_shows_usage_too_many_args
run_test_case "ask_yn uses default yes when no input available" test_ask_yn_uses_default_yes_when_no_input
run_test_case "ask_yn uses default no when no input available" test_ask_yn_uses_default_no_when_no_input
run_test_case "ask_yn shows [Y/n] hint with yes default" test_ask_yn_shows_yes_hint_in_prompt
run_test_case "ask_yn shows [y/N] hint with no default" test_ask_yn_shows_no_hint_in_prompt
run_test_case "ask_yn shows [y/n] hint without default" test_ask_yn_shows_neutral_hint_no_default
run_test_case "ask_yn accepts Y as default" test_ask_yn_accepts_uppercase_Y_default
run_test_case "ask_yn accepts N as default" test_ask_yn_accepts_uppercase_N_default
run_test_case "ask_yn accepts YES as default" test_ask_yn_accepts_uppercase_YES_default
run_test_case "ask_yn accepts NO as default" test_ask_yn_accepts_uppercase_NO_default
finish_tests
