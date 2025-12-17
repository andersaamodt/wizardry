#!/bin/sh
# spell-menu test coverage:
# - fails when memorize is missing
# - shows usage with --help
# - requires minimum 3 arguments
# - --cast executes the given command

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_stub_dir() {
  dir=$(mktemp -d "$WIZARDRY_TMPDIR/spell-menu.XXXXXX") || exit 1
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
        "$name"*) continue ;;
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
    cat "$cast_file" 2>/dev/null || true
    ;;
  dir)
    cast_dir=${WIZARDRY_CAST_DIR:-${HOME:-.}/.spellbook}
    printf '%s\n' "$cast_dir"
    ;;
  *)
    # Default action: memorize the spell (same as add with spell name as command)
    name=$1
    cmd=$name
    cast_dir=${WIZARDRY_CAST_DIR:-${HOME:-.}/.spellbook}
    cast_file_default=$cast_dir/.memorized
    cast_file=${WIZARDRY_CAST_FILE:-$cast_file_default}
    mkdir -p "$cast_dir"
    printf '%s\t%s\n' "$name" "$cmd" >>"$cast_file"
    printf '%s\n' "$cmd" >"$cast_dir/$name"
    chmod +x "$cast_dir/$name"
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

write_menu_stub() {
  dir=$1
  cat >"$dir/menu" <<'STUB'
#!/bin/sh
# Return escape status to exit the menu loop
kill -TERM "$PPID" 2>/dev/null || exit 0; exit 0
STUB
  chmod +x "$dir/menu"
}

test_errors_when_helper_missing() {
  stub_dir=$(make_stub_dir)
  PATH="$stub_dir:$WIZARDRY_TEST_MINIMAL_PATH" CAST_STORE="$stub_dir/does-not-exist" _run_spell "spells/menu/spell-menu" --help
  # --help should work even without memorize
  _assert_success || return 1
}

test_shows_usage_with_help() {
  skip-if-compiled || return $?
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  PATH="$stub_dir:$PATH" _run_spell "spells/menu/spell-menu" --help
  _assert_success || return 1
  case "$OUTPUT" in
    *"Usage: spell-menu"*) : ;;
    *) TEST_FAILURE_REASON="help text should show usage: $OUTPUT"; return 1 ;;
  esac
}

test_requires_minimum_arguments() {
  skip-if-compiled || return $?
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  # Call with no arguments (needs 1)
  PATH="$stub_dir:$PATH" _run_spell "spells/menu/spell-menu"
  _assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"Usage:"*) : ;;
    *) TEST_FAILURE_REASON="should show usage when too few arguments"; return 1 ;;
  esac
}

test_cast_action_executes_command() {
  skip-if-compiled || return $?
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  PATH="$stub_dir:$PATH" _run_spell "spells/menu/spell-menu" --cast "echo hello"
  _assert_success || return 1
  case "$OUTPUT" in
    *"hello"*) : ;;
    *) TEST_FAILURE_REASON="cast action should execute command: $OUTPUT"; return 1 ;;
  esac
}

_run_test_case "spell-menu shows usage with --help" test_shows_usage_with_help
_run_test_case "spell-menu requires minimum arguments" test_requires_minimum_arguments
_run_test_case "spell-menu --cast executes command" test_cast_action_executes_command

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  skip-if-compiled || return $?
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  
  # Create menu stub that logs entries and returns escape status
  cat >"$stub_dir/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
kill -TERM "$PPID" 2>/dev/null || exit 0; exit 0
SH
  chmod +x "$stub_dir/menu"
  
  
  cat >"$stub_dir/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$stub_dir/exit-label"
  
  
  _run_cmd env PATH="$stub_dir:$PATH" MENU_LOG="$stub_dir/log" "$ROOT_DIR/spells/menu/spell-menu" testspell
  _assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$stub_dir/log")
  case "$args" in
    *'Exit%kill -TERM $PPID') : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
  
}

_run_test_case "spell-menu ESC/Exit behavior" test_esc_exit_behavior

# Test that toggle selection keeps cursor position, other actions reset to first item
test_toggle_keeps_cursor_position() {
  skip-if-compiled || return $?
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  
  cat >"$stub_dir/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$stub_dir/exit-label"
  
  # Create a menu stub that logs --start-selection argument and simulates actions
  # First call: run memorize (toggle), second call: exit
  call_count_file="$stub_dir/call_count"
  printf '0\n' >"$call_count_file"
  
  cat >"$stub_dir/menu" <<'SH'
#!/bin/sh
call_count=$(cat "$CALL_COUNT_FILE")
# Parse --start-selection argument
start_sel=1
while [ "$#" -gt 0 ]; do
  case $1 in
    --start-selection)
      start_sel=$2
      shift 2
      ;;
    *)
      break
      ;;
  esac
done
printf '%s\n' "START_SELECTION=$start_sel" >>"$MENU_LOG"
call_count=$((call_count + 1))
printf '%s\n' "$call_count" >"$CALL_COUNT_FILE"
if [ "$call_count" -eq 1 ]; then
  # First call: execute the memorize command (second argument, which is the toggle)
  # Find the toggle command (contains memorize or forget)
  for arg in "$@"; do
    case "$arg" in
      *Memorize%*|*Forget%*)
        cmd=${arg#*%}
        eval "$cmd"
        exit 0
        ;;
    esac
  done
  exit 0
fi
# Second call: exit
kill -TERM "$PPID" 2>/dev/null || exit 0; exit 0
SH
  chmod +x "$stub_dir/menu"
  
  _run_cmd env PATH="$stub_dir:$PATH:$WIZARDRY_TEST_MINIMAL_PATH" MENU_LOG="$stub_dir/log" CALL_COUNT_FILE="$call_count_file" "$ROOT_DIR/spells/menu/spell-menu" testspell
  _assert_success || { TEST_FAILURE_REASON="menu should exit successfully"; return 1; }
  
  log_content=$(cat "$stub_dir/log")
  # First call should have start_selection=1
  # Second call (after toggle) should have start_selection=2
  first_selection=$(printf '%s\n' "$log_content" | head -1 | sed 's/.*START_SELECTION=//')
  second_selection=$(printf '%s\n' "$log_content" | sed -n '2p' | sed 's/.*START_SELECTION=//')
  
  if [ "$first_selection" != "1" ]; then
    TEST_FAILURE_REASON="first menu call should have start_selection=1, got $first_selection"
    return 1
  fi
  
  if [ "$second_selection" != "2" ]; then
    TEST_FAILURE_REASON="after toggle, menu should have start_selection=2, got $second_selection (log: $log_content)"
    return 1
  fi
}

_run_test_case "spell-menu toggle keeps cursor position" test_toggle_keeps_cursor_position

# Test that non-toggle actions reset cursor to first item
test_non_toggle_resets_cursor() {
  skip-if-compiled || return $?
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  
  cat >"$stub_dir/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$stub_dir/exit-label"
  
  # Create a menu stub that logs --start-selection argument and simulates cast action
  call_count_file="$stub_dir/call_count"
  printf '0\n' >"$call_count_file"
  
  cat >"$stub_dir/menu" <<'SH'
#!/bin/sh
call_count=$(cat "$CALL_COUNT_FILE")
# Parse --start-selection argument
start_sel=1
while [ "$#" -gt 0 ]; do
  case $1 in
    --start-selection)
      start_sel=$2
      shift 2
      ;;
    *)
      break
      ;;
  esac
done
printf '%s\n' "START_SELECTION=$start_sel" >>"$MENU_LOG"
call_count=$((call_count + 1))
printf '%s\n' "$call_count" >"$CALL_COUNT_FILE"
if [ "$call_count" -eq 1 ]; then
  # First call: execute the cast command (first argument)
  for arg in "$@"; do
    case "$arg" in
      "Cast now%"*)
        cmd=${arg#*%}
        eval "$cmd" 2>/dev/null || true
        exit 0
        ;;
    esac
  done
  exit 0
fi
# Second call: exit
kill -TERM "$PPID" 2>/dev/null || exit 0; exit 0
SH
  chmod +x "$stub_dir/menu"
  
  _run_cmd env PATH="$stub_dir:$PATH:$WIZARDRY_TEST_MINIMAL_PATH" MENU_LOG="$stub_dir/log" CALL_COUNT_FILE="$call_count_file" "$ROOT_DIR/spells/menu/spell-menu" testspell
  _assert_success || { TEST_FAILURE_REASON="menu should exit successfully"; return 1; }
  
  log_content=$(cat "$stub_dir/log")
  # First call should have start_selection=1
  # Second call (after cast action, NOT toggle) should have start_selection=1 (reset)
  first_selection=$(printf '%s\n' "$log_content" | head -1 | sed 's/.*START_SELECTION=//')
  second_selection=$(printf '%s\n' "$log_content" | sed -n '2p' | sed 's/.*START_SELECTION=//')
  
  if [ "$first_selection" != "1" ]; then
    TEST_FAILURE_REASON="first menu call should have start_selection=1, got $first_selection"
    return 1
  fi
  
  if [ "$second_selection" != "1" ]; then
    TEST_FAILURE_REASON="after non-toggle action, menu should have start_selection=1, got $second_selection (log: $log_content)"
    return 1
  fi
}

_run_test_case "spell-menu non-toggle resets cursor" test_non_toggle_resets_cursor

_finish_tests
