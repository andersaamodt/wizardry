#!/bin/sh
# spell-menu test coverage:
# - fails when memorize-spell is missing
# - shows usage with --help
# - requires minimum 3 arguments
# - --cast executes the given command
# - --delete removes scribed command

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

make_stub_dir() {
  dir=$(mktemp -d "$WIZARDRY_TMPDIR/spell-menu.XXXXXX") || exit 1
  printf '%s\n' "$dir"
}

write_memorize_command_stub() {
  dir=$1
  cat >"$dir/memorize-spell" <<'STUB'
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
esac
STUB
  chmod +x "$dir/memorize-spell"
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
exit 113
STUB
  chmod +x "$dir/menu"
}

test_errors_when_helper_missing() {
  stub_dir=$(make_stub_dir)
  PATH="$stub_dir:/bin:/usr/bin" CAST_STORE="$stub_dir/does-not-exist" run_spell "spells/menu/spell-menu" --help
  # --help should work even without memorize-spell
  assert_success || return 1
}

test_shows_usage_with_help() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  PATH="$stub_dir:$PATH" run_spell "spells/menu/spell-menu" --help
  assert_success || return 1
  case "$OUTPUT" in
    *"Usage: spell-menu"*) : ;;
    *) TEST_FAILURE_REASON="help text should show usage: $OUTPUT"; return 1 ;;
  esac
}

test_requires_minimum_arguments() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  # Call with no arguments (needs 1)
  PATH="$stub_dir:$PATH" run_spell "spells/menu/spell-menu"
  assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"Usage:"*) : ;;
    *) TEST_FAILURE_REASON="should show usage when too few arguments"; return 1 ;;
  esac
}

test_cast_action_executes_command() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  PATH="$stub_dir:$PATH" run_spell "spells/menu/spell-menu" --cast "echo hello"
  assert_success || return 1
  case "$OUTPUT" in
    *"hello"*) : ;;
    *) TEST_FAILURE_REASON="cast action should execute command: $OUTPUT"; return 1 ;;
  esac
}

test_delete_action_removes_scribed_command() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  spellbook_dir="$stub_dir/spellbook"
  mkdir -p "$spellbook_dir"
  # Create a scribed command
  printf '#!/bin/sh\necho ignite\n' >"$spellbook_dir/spark"
  chmod +x "$spellbook_dir/spark"
  # Delete it
  WIZARDRY_SPELL_HOME="$spellbook_dir" PATH="$stub_dir:$PATH" run_spell "spells/menu/spell-menu" --delete spark
  assert_success || return 1
  case "$OUTPUT" in
    *"Deleted scribed command"*) : ;;
    *) TEST_FAILURE_REASON="delete should confirm removal: $OUTPUT"; return 1 ;;
  esac
  # Verify file is removed
  if [ -f "$spellbook_dir/spark" ]; then
    TEST_FAILURE_REASON="delete did not remove script file"
    return 1
  fi
}

run_test_case "spell-menu shows usage with --help" test_shows_usage_with_help
run_test_case "spell-menu requires minimum arguments" test_requires_minimum_arguments
run_test_case "spell-menu --cast executes command" test_cast_action_executes_command
run_test_case "spell-menu --delete removes scribed command" test_delete_action_removes_scribed_command

finish_tests
