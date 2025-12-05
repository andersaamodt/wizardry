#!/bin/sh
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


detect_magic_reports_found_files() {
  tmpdir=$(make_tempdir)
  stub="$tmpdir/read-magic"
  cat <<'STUB' >"$stub"
#!/bin/sh
case "$1" in
  a.txt) printf '%s\n' 'sigil:alpha' 'mark:beta' ;;
  b.txt) : ;; # no attributes so should be skipped
  *) exit 1 ;;
esac
STUB
  chmod +x "$stub"

  printf 'content' >"$tmpdir/a.txt"
  printf 'other' >"$tmpdir/b.txt"

  NO_COLOR=1 DETECT_MAGIC_READ_MAGIC="$stub" run_spell_in_dir "$tmpdir" "spells/divination/detect-magic"
  assert_success || return 1
  assert_output_contains "File" || return 1
  assert_output_contains "a.txt" || return 1
  case "$OUTPUT" in
    *b.txt*) TEST_FAILURE_REASON="file without attributes was listed"; return 1 ;;
  esac
}

detect_magic_handles_empty_rooms() {
  tmpdir=$(make_tempdir)
  NO_COLOR=1 run_spell_in_dir "$tmpdir" "spells/divination/detect-magic"
  assert_success || return 1
  assert_output_contains "No enchantments reveal themselves today." || return 1
}

detect_magic_shows_usage() {
  run_spell "spells/divination/detect-magic" --help
  assert_success || return 1
  assert_output_contains "Usage: detect-magic" || return 1
}

detect_magic_supports_plain_sh_and_skips_dirs() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/keep_out"
  stub="$tmpdir/read-magic"
  cat <<'STUB' >"$stub"
#!/bin/sh
case "$1" in
  aura.txt) printf 'sigil:1\n' ;;
  *) exit 1 ;;
esac
STUB
  chmod +x "$stub"

  printf 'note' >"$tmpdir/aura.txt"
  NO_COLOR=1 DETECT_MAGIC_READ_MAGIC="$stub" RUN_CMD_WORKDIR="$tmpdir" run_cmd sh "$ROOT_DIR/spells/divination/detect-magic"
  assert_success || return 1
  case "$OUTPUT" in
    *keep_out*) TEST_FAILURE_REASON="directory appeared in output"; return 1 ;;
  esac
  assert_output_contains "aura.txt" || return 1
}

detect_magic_handles_faint_auras() {
  tmpdir=$(make_tempdir)
  stub="$tmpdir/read-magic"
  cat <<'STUB' >"$stub"
#!/bin/sh
if [ "$1" = "glimmer.txt" ]; then
  i=1
  while [ "$i" -le 20 ]; do
    printf 'glyph:%d\n' "$i"
    i=$((i + 1))
  done
fi
STUB
  chmod +x "$stub"
  : >"$tmpdir/glimmer.txt"

  DETECT_MAGIC_READ_MAGIC="$stub" run_spell_in_dir "$tmpdir" "spells/divination/detect-magic"
  assert_success || return 1
  assert_output_contains "faint glimmer" || return 1
}

detect_magic_handles_dense_rooms() {
  tmpdir=$(make_tempdir)
  stub="$tmpdir/read-magic"
  cat <<'STUB' >"$stub"
#!/bin/sh
case "$1" in
  torrent.txt)
    i=1
    while [ "$i" -le 130 ]; do
      printf 'sigil:%d\n' "$i"
      i=$((i + 1))
    done
    ;;
  *) exit 0 ;;
esac
STUB
  chmod +x "$stub"
  : >"$tmpdir/torrent.txt"

  DETECT_MAGIC_READ_MAGIC="$stub" run_spell_in_dir "$tmpdir" "spells/divination/detect-magic"
  assert_success || return 1
  assert_output_contains "off the charts" || return 1
}

detect_magic_handles_colour_toggle() {
  tmpdir=$(make_tempdir)
  stub="$tmpdir/read-magic"
  cat <<'STUB' >"$stub"
#!/bin/sh
printf 'sigil:1\n'
STUB
  chmod +x "$stub"
  : >"$tmpdir/soft.txt"

  NO_COLOR=1 DETECT_MAGIC_READ_MAGIC="$stub" run_spell_in_dir "$tmpdir" "spells/divination/detect-magic"
  assert_success || return 1
  case "$OUTPUT" in
    *"\033"*) TEST_FAILURE_REASON="colour codes present despite NO_COLOR"; return 1 ;;
  esac
  assert_output_contains "soft.txt" || return 1
}

detect_magic_reports_missing_helper() {
  tmpdir=$(make_tempdir)
  cp "$ROOT_DIR/spells/divination/detect-magic" "$tmpdir/detect-magic"
  chmod +x "$tmpdir/detect-magic"

  run_cmd env PATH="/bin:/usr/bin" "$tmpdir/detect-magic"
  assert_failure || return 1
  case "$OUTPUT" in
    "") : ;;
    *) TEST_FAILURE_REASON="output should be empty when helper missing"; return 1 ;;
  esac
  assert_error_contains "read-magic spell is missing" || return 1
}

detect_magic_skips_unreadable_enchantments() {
  tmpdir=$(make_tempdir)
  stub="$tmpdir/read-magic"
  cat <<'STUB' >"$stub"
#!/bin/sh
case "$1" in
  shy.txt) exit 1 ;;
  eager.txt) printf 'sigil:1\n' ;;
esac
STUB
  chmod +x "$stub"
  : >"$tmpdir/shy.txt"
  : >"$tmpdir/eager.txt"

  DETECT_MAGIC_READ_MAGIC="$stub" run_spell_in_dir "$tmpdir" "spells/divination/detect-magic"
  assert_success || return 1
  case "$OUTPUT" in
    *shy.txt*) TEST_FAILURE_REASON="unreadable file was listed"; return 1 ;;
  esac
  assert_output_contains "eager.txt" || return 1
}

detect_magic_reports_helper_errors_without_stopping() {
  tmpdir=$(make_tempdir)
  stub="$tmpdir/read-magic"
  cat <<'STUB' >"$stub"
#!/bin/sh
case "$1" in
  troubled.txt)
    printf 'oh no\n' >&2
    exit 3
    ;;
  steady.txt)
    printf 'sigil:1\n'
    ;;
esac
STUB
  chmod +x "$stub"

  : >"$tmpdir/troubled.txt"
  : >"$tmpdir/steady.txt"

  NO_COLOR=1 DETECT_MAGIC_READ_MAGIC="$stub" run_spell_in_dir "$tmpdir" "spells/divination/detect-magic"
  assert_success || return 1
  assert_output_contains "steady.txt" || return 1
  case "$OUTPUT" in
    *troubled.txt*) TEST_FAILURE_REASON="failed file should be skipped"; return 1 ;;
  esac
  assert_error_contains "failed to read troubled.txt" || return 1
}

detect_magic_skips_malformed_helper_output() {
  tmpdir=$(make_tempdir)
  stub="$tmpdir/read-magic"
  cat <<'STUB' >"$stub"
#!/bin/sh
case "$1" in
  warped.txt) printf 'not-a-pair\n' ;;
  good.txt) printf 'sigil:2\n' ;;
esac
STUB
  chmod +x "$stub"

  : >"$tmpdir/warped.txt"
  : >"$tmpdir/good.txt"

  NO_COLOR=1 DETECT_MAGIC_READ_MAGIC="$stub" run_spell_in_dir "$tmpdir" "spells/divination/detect-magic"
  assert_success || return 1
  assert_output_contains "good.txt" || return 1
  case "$OUTPUT" in
    *warped.txt*) TEST_FAILURE_REASON="malformed file should be skipped"; return 1 ;;
  esac
  assert_error_contains "ignoring malformed output from warped.txt" || return 1
}

run_test_case "detect-magic lists files with attributes" detect_magic_reports_found_files
run_test_case "detect-magic reports when nothing is enchanted" detect_magic_handles_empty_rooms
run_test_case "detect-magic shows usage" detect_magic_shows_usage
run_test_case "detect-magic stays POSIX and skips directories" detect_magic_supports_plain_sh_and_skips_dirs
run_test_case "detect-magic describes faint auras" detect_magic_handles_faint_auras
run_test_case "detect-magic narrates dense rooms" detect_magic_handles_dense_rooms
run_test_case "detect-magic disables colour on request" detect_magic_handles_colour_toggle
run_test_case "detect-magic warns when helper missing" detect_magic_reports_missing_helper
run_test_case "detect-magic skips unreadable files" detect_magic_skips_unreadable_enchantments
run_test_case "detect-magic reports helper failures" detect_magic_reports_helper_errors_without_stopping
run_test_case "detect-magic skips malformed helper output" detect_magic_skips_malformed_helper_output

finish_tests
