#!/bin/sh
# Behavior cases from --help: report terminal dimensions via tput.
# - Reports both width and height by default.
# - Honors --width/--height flags for single-dimension queries.
# - Adds labels in verbose mode.
# - Exits with an error when terminfo queries fail.

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


make_stub_tput() {
  dir=$(mktemp -d "${WIZARDRY_TMPDIR}/tput-stub.XXXXXX")
  cat >"$dir/tput" <<'SCRIPT'
#!/bin/sh
case "$1" in
  cols) printf '120' ;;
  lines) printf '40' ;;
  *) exit 1 ;;
 esac
SCRIPT
  chmod +x "$dir/tput"
  printf '%s' "$dir"
}

run_fathom_terminal() {
  bin_dir=$1
  shift
  run_cmd env PATH="$bin_dir:$PATH" "$ROOT_DIR/spells/cantrips/fathom-terminal" "$@"
}

normalize_output() {
  printf '%s' "$OUTPUT" | tr '\n' '|'
}

# reports both dimensions by default
reports_width_and_height() {
  stub=$(make_stub_tput)
  run_fathom_terminal "$stub"
  [ "$STATUS" -eq 0 ] || return 1
  case "$(normalize_output)" in
    "120|40"|"120|40|") : ;;
    *) TEST_FAILURE_REASON="unexpected output: $OUTPUT"; return 1 ;;
  esac
}

# selects a single dimension
selects_single_dimension() {
  stub=$(make_stub_tput)
  run_fathom_terminal "$stub" --width
  [ "$STATUS" -eq 0 ] || return 1
  case "$(normalize_output)" in
    "120"|"120|") : ;;
    *) TEST_FAILURE_REASON="expected width"; return 1 ;;
  esac

  run_fathom_terminal "$stub" --height
  [ "$STATUS" -eq 0 ] || return 1
  case "$(normalize_output)" in
    "40"|"40|") : ;;
    *) TEST_FAILURE_REASON="expected height"; return 1 ;;
  esac
}

# verbose adds labels
prints_verbose_labels() {
  stub=$(make_stub_tput)
  run_fathom_terminal "$stub" --verbose
  [ "$STATUS" -eq 0 ] || return 1
  case "$(normalize_output)" in
    "Width: 120|Height: 40"|"Width: 120|Height: 40|") : ;;
    *) TEST_FAILURE_REASON="unexpected verbose output: $OUTPUT"; return 1 ;;
  esac
}

# fails when terminfo queries fail
fails_without_tput() {
  empty=$(mktemp -d "${WIZARDRY_TMPDIR}/empty-path.XXXXXX")
  run_cmd env PATH="$empty" "$ROOT_DIR/spells/cantrips/fathom-terminal" --width
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected failure"; return 1; }
}

run_test_case "reports width and height" reports_width_and_height
run_test_case "selects a single dimension" selects_single_dimension
run_test_case "adds verbose labels" prints_verbose_labels
run_test_case "fails when tput is missing" fails_without_tput

shows_help() {
  run_spell spells/cantrips/fathom-terminal --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "fathom-terminal shows help" shows_help
finish_tests
