#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - cast lists stored spells without opening a menu when --list is used
# - cast exits gracefully when no spells are stored
# - cast feeds stored spells into the menu and honors escape status
# - cast --dir prints the directory containing spell scripts
# - cast --help shows usage information
# - cast fails when menu dependency is missing

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


make_stub_cast_list() {
  tmp=$1
  alias_name=$2
  command_text=$3
  cat >"$tmp/memorize" <<SH
#!/bin/sh
case "\$1" in
  list)
    alias_name="$alias_name"
    command_text="$command_text"
    if [ -n "\$alias_name" ]; then
      printf '%s\t%s\n' "\$alias_name" "\$command_text"
    fi
    ;;
  dir)
    printf '%s\n' "$tmp"
    ;;
esac
SH
  chmod +x "$tmp/memorize"
  mkdir -p "$tmp"
  if [ -n "$alias_name" ] && [ -n "$command_text" ]; then
    # Create spell script in same format as memorize write_spell_script
    escaped_cmd=$(printf '%s' "$command_text" | sed "s/'/'\\\\''/g")
    cat >"$tmp/$alias_name" <<EOF
#!/bin/sh
exec sh -c '$escaped_cmd' "\$0" "\$@"
EOF
    chmod +x "$tmp/$alias_name"
  fi
}

make_stub_menu() {
  tmp=$1
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
kill -TERM "$PPID" 2>/dev/null || exit 0; exit 0
SH
  chmod +x "$tmp/menu"
}

make_stub_require() {
  tmp=$1
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/require-command"
}

make_failing_require() {
  tmp=$1
  cat >"$tmp/require" <<'SH'
#!/bin/sh
printf '%s\n' "The casting menu needs the '\''menu'\'' command." >&2
exit 1
SH
  chmod +x "$tmp/require"
}

test_cast_fails_without_menu_dependency() {
  tmp=$(make_tempdir)
  make_stub_cast_list "$tmp" fire "cast fire"
  make_failing_require "$tmp"
  PATH="$tmp:$PATH" run_cmd env CAST_STORE="$tmp/memorize" "$ROOT_DIR/spells/menu/cast"
  assert_failure || return 1
  assert_error_contains "menu" || return 1
}

test_cast_lists_stored_spells() {
  tmp=$(make_tempdir)
  make_stub_cast_list "$tmp" fire "cast fire"
  PATH="$tmp:$PATH" run_cmd env CAST_STORE="$tmp/memorize" "$ROOT_DIR/spells/menu/cast" --list
  assert_success && assert_output_contains "$(printf 'fire\tcast fire')"
}

test_cast_prints_empty_message() {
  tmp=$(make_tempdir)
  make_stub_cast_list "$tmp" "" ""
  make_stub_require "$tmp"
  PATH="$tmp:$PATH" run_cmd env CAST_STORE="$tmp/memorize" "$ROOT_DIR/spells/menu/cast"
  assert_success && assert_output_contains "No spells are available to cast."
}

test_cast_sends_entries_to_menu() {
  tmp=$(make_tempdir)
  make_stub_cast_list "$tmp" fizz "cast fizz"
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  PATH="$tmp:$PATH" run_cmd env CAST_STORE="$tmp/memorize" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/cast"
  assert_success
  if [ ! -f "$tmp/log" ]; then
    TEST_FAILURE_REASON="menu was not invoked"
    return 1
  fi
  args=$(cat "$tmp/log")
  # Label is just alias; command (after %) is now the spell name directly (no wrapper scripts)
  case "$args" in
    *"Cast a Spell:"*"fizz%cast fizz"*'Exit%kill -TERM $PPID' ) : ;;
    *) TEST_FAILURE_REASON="menu did not receive stored spells"; return 1 ;;
  esac
}

test_cast_dir_prints_directory() {
  tmp=$(make_tempdir)
  make_stub_cast_list "$tmp" fire "cast fire"
  PATH="$tmp:$PATH" run_cmd env CAST_STORE="$tmp/memorize" "$ROOT_DIR/spells/menu/cast" --dir
  assert_success || return 1
  # The output should contain the temp directory path
  assert_output_contains "$tmp" || return 1
}

test_cast_help_shows_usage() {
  tmp=$(make_tempdir)
  make_stub_cast_list "$tmp" fire "cast fire"
  PATH="$tmp:$PATH" run_cmd env CAST_STORE="$tmp/memorize" "$ROOT_DIR/spells/menu/cast" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "--list" || return 1
  assert_output_contains "--dir" || return 1
}

test_cast_h_flag_shows_usage() {
  tmp=$(make_tempdir)
  make_stub_cast_list "$tmp" fire "cast fire"
  PATH="$tmp:$PATH" run_cmd env CAST_STORE="$tmp/memorize" "$ROOT_DIR/spells/menu/cast" -h
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
}

test_cast_invalid_argument_shows_usage() {
  tmp=$(make_tempdir)
  make_stub_cast_list "$tmp" fire "cast fire"
  PATH="$tmp:$PATH" run_cmd env CAST_STORE="$tmp/memorize" "$ROOT_DIR/spells/menu/cast" --invalid
  assert_failure || return 1
  # Should print usage to stderr
  assert_error_contains "Usage:" || return 1
}

test_cast_list_empty_returns_nothing() {
  tmp=$(make_tempdir)
  make_stub_cast_list "$tmp" "" ""
  PATH="$tmp:$PATH" run_cmd env CAST_STORE="$tmp/memorize" "$ROOT_DIR/spells/menu/cast" --list
  assert_success || return 1
  # Output should be empty when no spells stored
  if [ -n "$OUTPUT" ]; then
    TEST_FAILURE_REASON="expected empty output but got: $OUTPUT"
    return 1
  fi
}

test_cast_shows_alias_without_command_in_label() {
  tmp=$(make_tempdir)
  make_stub_cast_list "$tmp" spark "echo spark"
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  PATH="$tmp:$PATH" run_cmd env CAST_STORE="$tmp/memorize" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/cast"
  assert_success || return 1
  # The menu label is the alias, and command (after %) is the spell name directly
  args=$(cat "$tmp/log")
  case "$args" in
    *"spark%echo spark"*) : ;;
    *) TEST_FAILURE_REASON="expected alias-only label in menu: $args"; return 1 ;;
  esac
}

run_test_case "cast lists stored spells" test_cast_lists_stored_spells
run_test_case "cast exits when no stored spells" test_cast_prints_empty_message
run_test_case "cast feeds spells into menu" test_cast_sends_entries_to_menu
run_test_case "cast --dir prints directory" test_cast_dir_prints_directory
run_test_case "cast --help shows usage" test_cast_help_shows_usage
run_test_case "cast -h shows usage" test_cast_h_flag_shows_usage
run_test_case "cast invalid argument shows usage" test_cast_invalid_argument_shows_usage
run_test_case "cast --list with no spells returns empty" test_cast_list_empty_returns_nothing
run_test_case "cast shows alias without command in label" test_cast_shows_alias_without_command_in_label
run_test_case "cast fails without menu dependency" test_cast_fails_without_menu_dependency

# Test that spell name equals command doesn't show duplicate
test_cast_no_duplicate_when_alias_equals_command() {
  tmp=$(make_tempdir)
  # Create a memorize stub where alias = command (e.g., "myspell" and "myspell")
  make_stub_cast_list "$tmp" myspell "myspell"
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  PATH="$tmp:$PATH" run_cmd env CAST_STORE="$tmp/memorize" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/cast"
  assert_success || return 1
  args=$(cat "$tmp/log")
  # Should show just "myspell" not "myspell – myspell"
  case "$args" in
    *"myspell – myspell%"*)
      TEST_FAILURE_REASON="duplicate spell name in menu: $args"
      return 1
      ;;
    *"myspell%"*) : ;;
    *)
      TEST_FAILURE_REASON="expected spell name in menu: $args"
      return 1
      ;;
  esac
}

run_test_case "cast no duplicate when alias equals command" test_cast_no_duplicate_when_alias_equals_command

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  tmp=$(make_tempdir)
  make_stub_cast_list "$tmp" fizz "cast fizz"
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  run_cmd env PATH="$tmp:$PATH" CAST_STORE="$tmp/memorize" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/cast"
  assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *'Exit%kill -TERM $PPID') : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
}

run_test_case "cast ESC/Exit behavior" test_esc_exit_behavior

finish_tests
