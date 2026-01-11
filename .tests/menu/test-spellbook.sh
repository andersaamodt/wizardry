#!/bin/sh
# Spellbook menu helper coverage:
# - fails when memorize is missing
# - lists entries via --list
# - uses --memorize/--forget to manage the cast list
# - --scribe records commands as standalone scripts

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_stub_dir() {
  dir=$(mktemp -d "$WIZARDRY_TMPDIR/spellbook.XXXXXX") || exit 1
  # Create colors stub so spells can start
  cat >"$dir/colors" <<'SH'
#!/bin/sh
RESET=''
CYAN=''
GREY=''
PURPLE=''
YELLOW=''
THEME_CUSTOM=''
WIZARDRY_COLORS_AVAILABLE=0
SH
  chmod +x "$dir/colors"
  printf '%s\n' "$dir"
}

write_memorize_command_stub() {
  dir=$1
  cat >"$dir/memorize" <<'STUB'
#!/bin/sh
case $1 in
  add)
    shift
    name=$1
    shift
    cmd=$1
    shift || :
    while [ "$#" -gt 0 ]; do
      cmd="$cmd $1"
      shift
    done
    cast_dir=${WIZARDRY_CAST_DIR:-${HOME:-.}/.spellbook}
    cast_file_default=$cast_dir/.memorized
    cast_file=${WIZARDRY_CAST_FILE:-$cast_file_default}
    mkdir -p "$cast_dir"
    printf '%s\t%s\n' "$name" "$cmd" >>"$cast_file"
    printf '%s\n' "$cmd" >"$cast_dir/$name"
    chmod +x "$cast_dir/$name"
    ;;
  remove)
    shift
    name=$1
    cast_dir=${WIZARDRY_CAST_DIR:-${HOME:-.}/.spellbook}
    cast_file_default=$cast_dir/.memorized
    cast_file=${WIZARDRY_CAST_FILE:-$cast_file_default}
    tmp=$(mktemp)
    while IFS= read -r line || [ -n "$line" ]; do
      case $line in
        "$name"$'\t'*) continue ;;
        *) printf '%s\n' "$line" >>"$tmp" ;;
      esac
    done <"$cast_file"
    mv "$tmp" "$cast_file"
    rm -f "$cast_dir/$name"
    ;;
  list)
    cast_dir=${WIZARDRY_CAST_DIR:-${HOME:-.}/.spellbook}
    cast_file_default=$cast_dir/.memorized
    cast_file=${WIZARDRY_CAST_FILE:-$cast_file_default}
    cat "$cast_file" 2>/dev/null
    ;;
  dir)
    cast_dir=${WIZARDRY_CAST_DIR:-${HOME:-.}/.spellbook}
    printf '%s\n' "$cast_dir"
    ;;
esac
STUB
  chmod +x "$dir/memorize"
}

write_require_command_stub() {
  dir=$1
  cat >"$dir/require-command" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$dir/require-command"
}

test_errors_when_helper_missing() {
  skip-if-compiled || return $?
  stub_dir=$(make_stub_dir)
  PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$stub_dir:/bin:/usr/bin" CAST_STORE="$stub_dir/does-not-exist" run_spell "spells/menu/spellbook" --list
  assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"memorize helper is missing"*) : ;;
    *) TEST_FAILURE_REASON="helper missing warning not shown"; return 1 ;;
  esac
}

test_scribe_records_command() {
  skip-if-compiled || return $?
  # This test now validates that scribe-spell is the correct tool
  # spellbook should delegate to scribe-spell, not implement scribing itself
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  
  # spellbook should not support --scribe anymore
  PATH="$stub_dir:$PATH" run_spell "spells/menu/spellbook" --scribe spark "echo ignite"
  assert_failure || return 1
}

test_scribe_multiple_commands() {
  skip-if-compiled || return $?
  # This test now validates that scribe-spell is the correct tool
  # spellbook should delegate to scribe-spell, not implement scribing itself
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  
  # spellbook should not support --scribe anymore
  PATH="$stub_dir:$PATH" run_spell "spells/menu/spellbook" --scribe spark1 "echo ignite1"
  assert_failure || return 1
}

test_path_argument_accepted() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  # Test that spellbook --help includes the PATH usage
  PATH="$stub_dir:$PATH" run_spell "spells/menu/spellbook" --help
  assert_success || return 1
  case "$OUTPUT" in
    *"[PATH|"*) : ;;
    *) TEST_FAILURE_REASON="help text should mention PATH argument: $OUTPUT"; return 1 ;;
  esac
}

run_test_case "spellbook fails when helper missing" test_errors_when_helper_missing
run_test_case "spellbook rejects --scribe (use scribe-spell)" test_scribe_records_command
run_test_case "spellbook rejects multiple --scribe calls" test_scribe_multiple_commands
run_test_case "spellbook accepts path argument" test_path_argument_accepted

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  
  # Create menu stub that returns exit code 0 (normal success)
  cat >"$stub_dir/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit 0
SH
  chmod +x "$stub_dir/menu"
  
  cat >"$stub_dir/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$stub_dir/exit-label"
  
  # Run spellbook - it should work normally with exit code 0
  # Run directly without run_cmd wrapper to avoid hang
  env PATH="$stub_dir:$PATH" MENU_LOG="$stub_dir/log" "$ROOT_DIR/spells/menu/spellbook" &
  spellbook_pid=$!
  sleep 0.5
  kill -TERM "$spellbook_pid" 2>/dev/null || true
  wait "$spellbook_pid" 2>/dev/null || true
  
  # Verify that Exit menu item uses "kill -TERM $PPID" (transparent command)
  args=$(cat "$stub_dir/log" 2>/dev/null || printf '')
  case "$args" in
    *'Exit%kill -TERM $PPID'*|*'Back%kill -TERM $PPID'*) : ;;
    *) TEST_FAILURE_REASON="Exit/Back menu item should use 'kill -TERM \$PPID': $args"; return 1 ;;
  esac
}

run_test_case "spellbook ESC/Exit behavior" test_esc_exit_behavior


# Test via source-then-invoke pattern  

finish_tests
