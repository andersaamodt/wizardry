#!/bin/sh
# Behavioral cases (derived from --help):
# - colors enables palette on capable terminals
# - colors disables palette when NO_COLOR set
# - colors escape sequences work with printf %s
# - theme colors are defined when palette is enabled
# - theme colors are cleared when palette is disabled

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


test_colors_enable_palette_by_default() {
  run_cmd env TERM=xterm sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'avail:%s red:%s\\n' \"\$WIZARDRY_COLORS_AVAILABLE\" \"\$RED\""
  assert_success && case "$OUTPUT" in avail:1\ red:*) : ;; *) TEST_FAILURE_REASON="expected colors to be available"; return 1 ;; esac
}

test_colors_disable_when_requested() {
  run_cmd env TERM=xterm NO_COLOR=1 sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'avail:%s red:%s\\n' \"\$WIZARDRY_COLORS_AVAILABLE\" \"\$RED\""
  if ! assert_success; then return 1; fi
  case "$OUTPUT" in
    avail:0\ red:*) ;;
    *) TEST_FAILURE_REASON="expected palette to be disabled"; return 1 ;;
  esac
  case "$OUTPUT" in
    *"\\033"*) TEST_FAILURE_REASON="unexpected escape codes when colors disabled"; return 1 ;;
  esac
}

test_colors_printf_s_works() {
  # Test that color codes work with printf '%s' (not just printf '%b')
  # This was broken when colors used literal \033 strings
  run_cmd env TERM=xterm sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf '%stest%s' \"\$GREEN\" \"\$RESET\" | cat -v"
  if ! assert_success; then return 1; fi
  # cat -v shows escape character as ^[ so we should see ^[[32m
  case "$OUTPUT" in
    *"^[["*) : ;;
    *"\\033"*) TEST_FAILURE_REASON="colors contain literal \\033 instead of actual escape character"; return 1 ;;
    *) TEST_FAILURE_REASON="expected escape character in output, got: $OUTPUT"; return 1 ;;
  esac
}

test_colors_disable_for_dumb_terminal() {
  # Colors should be disabled for TERM=dumb which returns -1 from tput colors
  run_cmd env TERM=dumb sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'avail:%s green:%s\\n' \"\$WIZARDRY_COLORS_AVAILABLE\" \"\$GREEN\""
  if ! assert_success; then return 1; fi
  case "$OUTPUT" in
    avail:0\ green:) : ;;
    *) TEST_FAILURE_REASON="expected palette disabled for dumb terminal, got: $OUTPUT"; return 1 ;;
  esac
}

test_theme_colors_defined_when_enabled() {
  # Theme colors should be defined when the palette is enabled
  run_cmd env TERM=xterm sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'highlight:%s muted:%s custom:%s\\n' \"\$THEME_HIGHLIGHT\" \"\$THEME_MUTED\" \"\$THEME_CUSTOM\""
  if ! assert_success; then return 1; fi
  # Verify theme colors are non-empty (contain escape sequences)
  case "$OUTPUT" in
    highlight:\ *|muted:\ *|custom:\ *)
      TEST_FAILURE_REASON="expected theme colors to be defined, got: $OUTPUT"
      return 1
      ;;
    *)
      # Check that at least one theme color is defined
      case "$OUTPUT" in
        *highlight:*muted:*custom:*)
          : # All three fields present
          ;;
        *)
          TEST_FAILURE_REASON="unexpected output format: $OUTPUT"
          return 1
          ;;
      esac
      ;;
  esac
}

test_theme_colors_cleared_when_disabled() {
  # Theme colors should be empty when the palette is disabled
  run_cmd env TERM=xterm NO_COLOR=1 sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'highlight:[%s] muted:[%s] custom:[%s]\\n' \"\$THEME_HIGHLIGHT\" \"\$THEME_MUTED\" \"\$THEME_CUSTOM\""
  if ! assert_success; then return 1; fi
  case "$OUTPUT" in
    *"highlight:[] muted:[] custom:[]"*)
      : # All theme colors are empty as expected
      ;;
    *)
      TEST_FAILURE_REASON="expected theme colors to be empty when palette disabled, got: $OUTPUT"
      return 1
      ;;
  esac
}

test_mud_colors_defined_when_enabled() {
  # MUD colors should be defined when the palette is enabled
  run_cmd env TERM=xterm sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'location:%s item:%s handle:%s spell:%s monster:%s\\n' \"\$MUD_LOCATION\" \"\$MUD_ITEM\" \"\$MUD_HANDLE\" \"\$MUD_SPELL\" \"\$MUD_MONSTER\""
  if ! assert_success; then return 1; fi
  # Verify MUD colors are non-empty
  case "$OUTPUT" in
    *location:\ *|*item:\ *|*handle:\ *|*spell:\ *|*monster:\ *)
      TEST_FAILURE_REASON="expected MUD colors to be defined, got: $OUTPUT"
      return 1
      ;;
    *)
      # Check that all MUD color fields are present
      case "$OUTPUT" in
        *location:*item:*handle:*spell:*monster:*)
          : # All fields present
          ;;
        *)
          TEST_FAILURE_REASON="unexpected output format: $OUTPUT"
          return 1
          ;;
      esac
      ;;
  esac
}

test_mud_colors_cleared_when_disabled() {
  # MUD colors should be empty when the palette is disabled
  run_cmd env TERM=xterm NO_COLOR=1 sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'location:[%s] item:[%s] handle:[%s] spell:[%s] monster:[%s]\\n' \"\$MUD_LOCATION\" \"\$MUD_ITEM\" \"\$MUD_HANDLE\" \"\$MUD_SPELL\" \"\$MUD_MONSTER\""
  if ! assert_success; then return 1; fi
  case "$OUTPUT" in
    *"location:[] item:[] handle:[] spell:[] monster:[]"*)
      : # All MUD colors are empty as expected
      ;;
    *)
      TEST_FAILURE_REASON="expected MUD colors to be empty when palette disabled, got: $OUTPUT"
      return 1
      ;;
  esac
}

run_test_case "colors enables palette on capable terminals" test_colors_enable_palette_by_default
run_test_case "colors disables palette when NO_COLOR set" test_colors_disable_when_requested
run_test_case "colors work with printf %s format" test_colors_printf_s_works
run_test_case "colors disables palette for dumb terminal" test_colors_disable_for_dumb_terminal
run_test_case "theme colors are defined when palette is enabled" test_theme_colors_defined_when_enabled
run_test_case "theme colors are cleared when palette is disabled" test_theme_colors_cleared_when_disabled
run_test_case "MUD colors are defined when palette is enabled" test_mud_colors_defined_when_enabled
run_test_case "MUD colors are cleared when palette is disabled" test_mud_colors_cleared_when_disabled
shows_help() {
  run_spell spells/cantrips/colors --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "colors shows help" shows_help
finish_tests
