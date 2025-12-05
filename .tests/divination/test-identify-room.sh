#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

setup_layout() {
  tmpdir=$(_make_tempdir)
  IDENTIFY_ROOM_HOME="$tmpdir/home/me"
  TMPDIR="$tmpdir/tmp"
  mkdir -p "$IDENTIFY_ROOM_HOME" "$TMPDIR"
  export IDENTIFY_ROOM_HOME TMPDIR
}

identify_spell() {
  printf '%s\n' "spells/divination/identify-room"
}

test_help() {
  _run_spell "$(identify_spell)" --help
  _assert_success && _assert_output_contains "Usage: identify-room"
}

test_home_room() {
  setup_layout
  _run_spell "$(identify_spell)" "$IDENTIFY_ROOM_HOME"
  _assert_success || return 1
  _assert_output_contains "Home" || return 1
  _assert_output_contains "Your home folder." || return 1
}

test_other_home() {
  setup_layout
  other_home=$(dirname -- "$IDENTIFY_ROOM_HOME")/alex
  mkdir -p "$other_home"
  _run_spell "$(identify_spell)" "$other_home"
  _assert_success || return 1
  _assert_output_contains "alex" || return 1
  _assert_output_contains "home folder." || return 1
}

test_root_room() {
  setup_layout
  _run_spell "$(identify_spell)" /
  _assert_success || return 1
  _assert_output_contains "Root" || return 1
  _assert_output_contains "root of the filesystem" || return 1
}

test_list_flag() {
  setup_layout
  _run_spell "$(identify_spell)" --list
  _assert_success || return 1
  _assert_output_contains "/" || return 1
  _assert_output_contains "Temporary Directory" || return 1
}

test_unrecognized_room() {
  setup_layout
  unknown="$TMPDIR/unknown"
  mkdir -p "$unknown"
  _run_spell "$(identify_spell)" "$unknown"
  _assert_failure || return 1
  _assert_output_contains "no special meaning" || return 1
}

test_tmp_room() {
  setup_layout
  _run_spell "$(identify_spell)" /tmp
  _assert_success || return 1
  _assert_output_contains "Temporary Directory" || return 1
  _assert_output_contains "fleeting" || return 1
}

test_trailing_slash_tmp() {
  setup_layout
  _run_spell "$(identify_spell)" /tmp///
  _assert_success || return 1
  _assert_output_contains "Temporary Directory" || return 1
}

test_var_tmp_room() {
  setup_layout
  _run_spell "$(identify_spell)" /var/tmp
  _assert_success || return 1
  _assert_output_contains "Temporary Directory" || return 1
}

test_etc_room() {
  setup_layout
  _run_spell "$(identify_spell)" /etc
  _assert_success || return 1
  _assert_output_contains "Configuration Library" || return 1
  _assert_output_contains "System configuration" || return 1
}

test_usr_local_room() {
  setup_layout
  _run_spell "$(identify_spell)" /usr/local
  _assert_success || return 1
  _assert_output_contains "Local Workshop" || return 1
}

test_home_district() {
  setup_layout
  _run_spell "$(identify_spell)" /home
  _assert_success || return 1
  _assert_output_contains "Home Dwellings" || return 1
}

test_other_home_possessive_s() {
  setup_layout
  other_home=$(dirname -- "$IDENTIFY_ROOM_HOME")/chris
  mkdir -p "$other_home"
  _run_spell "$(identify_spell)" "$other_home"
  _assert_success || return 1
  _assert_output_contains "chris' Home" || return 1
  _assert_output_contains "chris' home folder." || return 1
}

test_list_argument_error() {
  setup_layout
  _run_spell "$(identify_spell)" --list /tmp
  _assert_failure || return 1
  _assert_error_contains "Usage: identify-room" || return 1
}

test_list_deduplicates_tmp() {
  setup_layout
  TMPDIR=/tmp
  export TMPDIR
  _run_spell "$(identify_spell)" --list
  _assert_success || return 1
  count=$(printf '%s' "$OUTPUT" | grep -c '^/tmp ')
  if [ "$count" -gt 1 ]; then
    TEST_FAILURE_REASON="temporary directory listed multiple times"
    return 1
  fi
}

_run_test_case "prints help" test_help
_run_test_case "identifies home" test_home_room
_run_test_case "identifies other home" test_other_home
_run_test_case "identifies root" test_root_room
_run_test_case "lists recognized rooms" test_list_flag
_run_test_case "reports unrecognized room" test_unrecognized_room
_run_test_case "identifies tmp" test_tmp_room
_run_test_case "identifies tmp with trailing slashes" test_trailing_slash_tmp
_run_test_case "identifies var tmp" test_var_tmp_room
_run_test_case "identifies etc" test_etc_room
_run_test_case "identifies usr local" test_usr_local_room
_run_test_case "identifies home district" test_home_district
_run_test_case "formats possessive names ending with s" test_other_home_possessive_s
_run_test_case "requires list flag to be standalone" test_list_argument_error
_run_test_case "lists tmp once" test_list_deduplicates_tmp
_finish_tests
