#!/bin/sh
# Behavioral cases (derived from --help):
# - ask_number retries until valid integer
# - ask_number enforces inclusive bounds
# - ask_number validates numeric bounds
# - ask_number fails without input
# - ask_number accepts boundary values
# - ask_number accepts negative numbers
# - ask_number reprompts on empty input
# - ask_number rejects non-integer MAX
# - ask_number rejects MIN greater than MAX
# - ask_number shows usage on wrong argument count
# - ask_number shows range hint in prompt

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


test_ask_number_accepts_range_after_retry() {
  tmp=$(make_tempdir)
  printf 'abc\n7\n' >"$tmp/answers"
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "\"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' 5 10 < \"$tmp/answers\""
  assert_success && assert_output_contains "7" && assert_error_contains "Whole number expected."
}

test_ask_number_enforces_bounds() {
  tmp=$(make_tempdir)
  printf '4\n5\n' >"$tmp/answers"
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "\"$ROOT_DIR/spells/cantrips/ask-number\" 'Choose' 5 6 < \"$tmp/answers\""
  assert_success && assert_output_contains "5" && assert_error_contains "Number must be between 5 and 6."
}

test_ask_number_rejects_invalid_bounds() {
  run_cmd "$ROOT_DIR/spells/cantrips/ask-number" "Question" notanint 3
  assert_failure && assert_error_contains "MIN must be an integer."
}

test_ask_number_requires_input() {
  run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask-number" "Question" 1 2
  assert_failure && assert_error_contains "No interactive input available."
}

# Test accepts minimum boundary value
test_ask_number_accepts_min_boundary() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '5\\n' | \"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' 5 10"
  assert_success && assert_output_contains "5"
}

# Test accepts maximum boundary value
test_ask_number_accepts_max_boundary() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '10\\n' | \"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' 5 10"
  assert_success && assert_output_contains "10"
}

# Test rejects value above maximum
test_ask_number_rejects_above_max() {
  tmp=$(make_tempdir)
  printf '11\n10\n' >"$tmp/answers"
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "\"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' 5 10 < \"$tmp/answers\""
  assert_success && assert_output_contains "10" && assert_error_contains "Number must be between 5 and 10."
}

# Test accepts negative numbers when range includes them
test_ask_number_accepts_negative() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '%s\\n' '-5' | \"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' -10 10"
  assert_success && assert_output_contains "-5"
}

# Test negative range bounds work
test_ask_number_negative_bounds() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '%s\\n' '-7' | \"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' -10 -5"
  assert_success && assert_output_contains "-7"
}

# Test empty input reprompts
test_ask_number_reprompts_on_empty() {
  tmp=$(make_tempdir)
  printf '\n7\n' >"$tmp/answers"
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "\"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' 5 10 < \"$tmp/answers\""
  assert_success && assert_output_contains "7" && assert_error_contains "Whole number expected."
}

# Test rejects non-integer MAX
test_ask_number_rejects_invalid_max() {
  run_cmd "$ROOT_DIR/spells/cantrips/ask-number" "Question" 1 notanint
  assert_failure && assert_error_contains "MAX must be an integer."
}

# Test rejects MIN greater than MAX
test_ask_number_rejects_min_gt_max() {
  run_cmd "$ROOT_DIR/spells/cantrips/ask-number" "Question" 10 5
  assert_failure && assert_error_contains "MIN must be less than or equal to MAX."
}

# Test shows usage with too few arguments
test_ask_number_shows_usage_too_few() {
  run_cmd "$ROOT_DIR/spells/cantrips/ask-number" "Question" 1
  assert_failure && assert_error_contains "Usage:"
}

# Test shows usage with too many arguments
test_ask_number_shows_usage_too_many() {
  run_cmd "$ROOT_DIR/spells/cantrips/ask-number" "Question" 1 10 extra
  assert_failure && assert_error_contains "Usage:"
}

# Test shows usage with no arguments
test_ask_number_shows_usage_no_args() {
  run_cmd "$ROOT_DIR/spells/cantrips/ask-number"
  assert_failure && assert_error_contains "Usage:"
}

# Test range hint appears in prompt
test_ask_number_shows_range_hint() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '5\\n' | \"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' 1 10"
  assert_success && assert_error_contains "[1-10]"
}

# Test accepts zero when in range
test_ask_number_accepts_zero() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '0\\n' | \"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' -5 5"
  assert_success && assert_output_contains "0"
}

# Test equal MIN and MAX (single valid value)
test_ask_number_equal_bounds() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '5\\n' | \"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' 5 5"
  assert_success && assert_output_contains "5"
}

run_test_case "ask_number retries until valid integer" test_ask_number_accepts_range_after_retry
run_test_case "ask_number enforces inclusive bounds" test_ask_number_enforces_bounds
run_test_case "ask_number validates numeric bounds" test_ask_number_rejects_invalid_bounds
run_test_case "ask_number fails without input" test_ask_number_requires_input
run_test_case "ask_number accepts minimum boundary" test_ask_number_accepts_min_boundary
run_test_case "ask_number accepts maximum boundary" test_ask_number_accepts_max_boundary
run_test_case "ask_number rejects above maximum" test_ask_number_rejects_above_max
run_test_case "ask_number accepts negative numbers" test_ask_number_accepts_negative
run_test_case "ask_number negative range bounds" test_ask_number_negative_bounds
run_test_case "ask_number reprompts on empty input" test_ask_number_reprompts_on_empty
run_test_case "ask_number rejects non-integer MAX" test_ask_number_rejects_invalid_max
run_test_case "ask_number rejects MIN greater than MAX" test_ask_number_rejects_min_gt_max
run_test_case "ask_number shows usage with too few args" test_ask_number_shows_usage_too_few
run_test_case "ask_number shows usage with too many args" test_ask_number_shows_usage_too_many
run_test_case "ask_number shows usage with no args" test_ask_number_shows_usage_no_args
run_test_case "ask_number shows range hint in prompt" test_ask_number_shows_range_hint
run_test_case "ask_number accepts zero" test_ask_number_accepts_zero
run_test_case "ask_number equal bounds" test_ask_number_equal_bounds
finish_tests
