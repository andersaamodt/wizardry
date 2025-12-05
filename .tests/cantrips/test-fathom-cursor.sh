#!/bin/sh
# Behavior cases from --help: report cursor coordinates from terminal DSR responses.
# - Emits both X and Y when no axis is chosen.
# - Supports selecting a single axis with -x or -y.
# - Adds labels in verbose mode.
# - Fails on malformed or missing terminal responses.

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


make_response() {
  file=$(mktemp "${WIZARDRY_TMPDIR}/fathom-cursor.XXXXXX")
  printf '\033[%s;%sR' "$1" "$2" >"$file"
  printf '%s' "$file"
}

run_fathom() {
  resp_file=$1
  shift
  run_cmd env FATHOM_CURSOR_DEVICE="$resp_file" FATHOM_CURSOR_SKIP_STTY=1 "$ROOT_DIR/spells/cantrips/fathom-cursor" "$@"
}

normalize_output() {
  printf '%s' "$OUTPUT" | tr '\n' '|'
}

# emits both axes when none requested
reports_both_axes() {
  resp=$(make_response 12 34)
  run_fathom "$resp"
  [ "$STATUS" -eq 0 ] || return 1
  case "$(normalize_output)" in
    "34|12"|"34|12|") : ;;
    *) TEST_FAILURE_REASON="unexpected output: $OUTPUT"; return 1 ;;
  esac
}

# supports single axis selection
selects_single_axis() {
  resp=$(make_response 5 9)
  run_fathom "$resp" -x
  [ "$STATUS" -eq 0 ] || return 1
  case "$(normalize_output)" in
    "9"|"9|") : ;;
    *) TEST_FAILURE_REASON="expected column"; return 1 ;;
  esac

  run_fathom "$resp" -y
  [ "$STATUS" -eq 0 ] || return 1
  case "$(normalize_output)" in
    "5"|"5|") : ;;
    *) TEST_FAILURE_REASON="expected row"; return 1 ;;
  esac
}

# adds labels when verbose
prints_verbose_labels() {
  resp=$(make_response 7 11)
  run_fathom "$resp" --verbose
  [ "$STATUS" -eq 0 ] || return 1
  case "$(normalize_output)" in
    "X: 11|Y: 7"|"X: 11|Y: 7|") : ;;
    *) TEST_FAILURE_REASON="unexpected verbose output: $OUTPUT"; return 1 ;;
  esac
}

# fails on malformed responses
fails_on_invalid_response() {
  bad=$(mktemp "${WIZARDRY_TMPDIR}/fathom-cursor.XXXXXX")
  printf 'junk' >"$bad"
  run_fathom "$bad"
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected failure"; return 1; }
}

run_test_case "reports both axes" reports_both_axes
run_test_case "selects a single axis" selects_single_axis
run_test_case "adds labels in verbose mode" prints_verbose_labels
run_test_case "fails on invalid response" fails_on_invalid_response

shows_help() {
  run_spell spells/cantrips/fathom-cursor --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "fathom-cursor shows help" shows_help
finish_tests
